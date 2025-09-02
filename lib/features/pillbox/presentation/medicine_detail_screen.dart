import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'package:pinkrain/core/models/medicine_model.dart';
import 'package:url_launcher/url_launcher.dart';

// import '../data/pillbox_model.dart'; // removed unused import
import '../../../core/util/helpers.dart';
import 'pillbox_notifier.dart';

class MedicineDetailScreen extends ConsumerStatefulWidget {
  final MedicineInventory inventory;

  const MedicineDetailScreen({
    super.key,
    required this.inventory
  });

  @override
  ConsumerState<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends ConsumerState<MedicineDetailScreen> {

  late Medicine medicine;
  String description = 'Loading medication information...';
  bool isLoading = true;
  bool isExpanded = false;

  // Sanitize text by removing reference symbols like [1], [4], [6], etc.
  String sanitizeText(String text) {
    // Regular expression to match reference symbols like [1], [4], [6], etc.
    return text.replaceAll(RegExp(r'\[\d+\]'), '');
  }

  Future<void> fetchMedUserDescription() async {
    try {
      final url = Uri.parse('https://en.wikipedia.org/wiki/${Uri.encodeComponent(medicine.name)}');
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      if (response.statusCode == 200) {
        final doc = parser.parse(response.body);
        final contentDiv = doc.querySelector('#mw-content-text .mw-parser-output');

        if (contentDiv != null) {
          List<String> summaryParas = [];

          for (var child in contentDiv.children) {
            if (child.localName == 'p' && child.text.trim().isNotEmpty) {
              summaryParas.add(child.text.trim());
            }
            if (child.localName == 'h2') break; // Stop at first section
          }

          if (summaryParas.isNotEmpty) {
            final summaryText = sanitizeText(summaryParas.join('\n\n'));
            setState(() {
              description = summaryText;
              isLoading = false;
            });
            return;
          }
        }

        // Default fallback message if no paragraphs found
        setState(() {
          description = "This medication is used to treat various conditions. Please consult your doctor for specific information.";
          isLoading = false;
        });
      } else if (response.statusCode == 404) {
        setState(() {
          description = "Information for this medication was not found in our database.";
          isLoading = false;
        });
      } else {
        setState(() {
          description = "Unable to load medication information. Status code: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        if (e is TimeoutException) {
          description = "Request timed out. Please check your internet connection and try again.";
        } else if (e.toString().contains('SocketException') || 
                  e.toString().contains('Connection refused') ||
                  e.toString().contains('Network is unreachable')) {
          description = "Network error. Please check your internet connection and try again.";
        } else {
          description = "Error loading medication information: ${e.toString().split('\n')[0]}";
        }
        isLoading = false;
      });
    }
  }

  // Returns the truncated version of the description (first 2-3 lines)
  String getTruncatedDescription() {
    if (description.contains("Failed") || 
        description.contains("Error") || 
        description.contains("Loading")) {
      return description;
    }

    final lines = description.split('\n');
    if (lines.length <= 3) {
      return description;
    }

    return lines.take(3).join('\n');
  }

  // Returns the expanded version of the description (up to 20 more lines)
  String getExpandedDescription() {
    if (description.contains("Failed") || 
        description.contains("Error") || 
        description.contains("Loading")) {
      return description;
    }

    final lines = description.split('\n');
    if (lines.length <= 3) {
      return description;
    }

    // Show first 3 lines plus up to 20 more lines
    final maxLines = lines.length > 23 ? 23 : lines.length;
    return lines.take(maxLines).join('\n');
  }

  @override
  void initState() {
    medicine = widget.inventory.medicine;
    fetchMedUserDescription();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(pillBoxProvider.notifier);
    final pillBox = ref.watch(pillBoxProvider);
    final inventory = pillBox.pillStock.firstWhere(
      (item) => item.medicine.name == medicine.name,
      orElse: () => widget.inventory,
    );
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                medicine.name,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      '${medicine.type} • ${medicine.specs.dosage} ${medicine.specs.unit}',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  futureBuildSvg(medicine.type, medicine.color, 50),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantity',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${inventory.quantity} pills left',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () {
                      _showFillUpDialog(context, notifier, inventory);
                    },
                    child: Text(
                      'fill-up >',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isLoading 
                      ? Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Loading medication information...',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              constraints: BoxConstraints(
                                maxHeight: isExpanded ? 300 : 70,
                              ),
                              child: Text(
                                isExpanded ? getExpandedDescription() : getTruncatedDescription(),
                                style: TextStyle(color: Colors.grey[600]),
                                overflow: TextOverflow.ellipsis,
                                maxLines: isExpanded ? 23 : 3,
                              ),
                            ),
                            if (!(description.contains("Failed") || description.contains("Error") || description.contains("Loading")))
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isExpanded = !isExpanded;
                                    });
                                  },
                                  child: Text(
                                    isExpanded ? 'Show less' : 'Read more',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            if (description.contains("Failed") || description.contains("Error"))
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      isLoading = true;
                                      description = 'Loading medication information...';
                                    });
                                    fetchMedUserDescription();
                                  },
                                  icon: Icon(Icons.refresh, color: Colors.white),
                                  label: Text('Retry', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            final url = Uri.parse('https://en.wikipedia.org/wiki/${Uri.encodeComponent(medicine.name)}');
                            launchUrl(url, mode: LaunchMode.externalApplication);
                          },
                          child: Text(
                            'Learn more on Wikipedia >',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            final formattedName = medicine.name.toLowerCase().replaceAll(' ', '-');
                            final url = Uri.parse('https://www.drugs.com/$formattedName.html');
                            launchUrl(url, mode: LaunchMode.externalApplication);
                          },
                          child: Text(
                            'Learn more on Drugs.com >',
                            style: TextStyle(color: Colors.pink[400]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              Center(
                child: TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red[50],
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.red[200]!),
                    ),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Remove Medication', style: TextStyle(color: Colors.red[700])),
                          backgroundColor: Colors.red[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                            side: BorderSide(color: Colors.red[200]!, width: 1.5),
                          ),
                          content: Text(
                            'Are you sure you want to remove ${medicine.name} from your pillbox?',
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                          actions: [
                            TextButton(
                              child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: Text('Remove', style: TextStyle(color: Colors.red[700])),
                              onPressed: () {
                                notifier.removeMedicine(medicine);
                                Navigator.of(context).pop();
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: Text('Remove from Pill Box',
                      style: TextStyle(color: Colors.red[700])),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

void _showFillUpDialog(BuildContext context, PillBoxNotifier notifier, MedicineInventory inventory) {
  int pillsChange = 0;
  bool isAdding = true;

  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Update Pills', style: TextStyle(color: Colors.pink[700])),
            backgroundColor: Colors.pink[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
              side: BorderSide(color: Colors.pink[200]!, width: 1.5),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isAdding ? 'Add pills' : 'Remove pills'),
                SizedBox(height: 10),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove),
                      onPressed: () {
                        setDialogState(() {
                          if (pillsChange > 0) pillsChange--;
                        });
                      },
                    ),
                    Text('$pillsChange'),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        setDialogState(() {
                          pillsChange++;
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Row(
                  children: [
                    Checkbox(
                      value: isAdding,
                      onChanged: (val) {
                        setDialogState(() {
                          isAdding = val ?? true;
                        });
                      },
                    ),
                    Text('Add'),
                    Checkbox(
                      value: !isAdding,
                      onChanged: (val) {
                        setDialogState(() {
                          isAdding = !(val ?? false);
                        });
                      },
                    ),
                    Text('Remove'),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  final pillsLeft = inventory.quantity;
                  int newPillCount;

                  if (isAdding) {
                    newPillCount = pillsLeft + pillsChange;
                  } else {
                    newPillCount = (pillsLeft - pillsChange).clamp(0, pillsLeft);
                  }
                  notifier.updateMedicineQuantity(inventory, newPillCount);
                  setState(() {}); // Refresh UI
                  Navigator.of(dialogContext).pop();
                },
                child: Text('Update'),
              ),
            ],
          );
        }
      );
    },
  );
}
}
