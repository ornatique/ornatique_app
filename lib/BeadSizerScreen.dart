import 'package:flutter/material.dart';

import 'ConstantColors/Color_Constant.dart';
import 'Constant_font/FontStyles.dart';

class BeadSizerScreen extends StatefulWidget {
  @override
  _BeadSizerScreenState createState() => _BeadSizerScreenState();
}

class _BeadSizerScreenState extends State<BeadSizerScreen> {
  double _diameter = 1.0;
  int? _expandedIndex;

  double calculateBeadVolume(double diameter) {
    double radius = diameter / 2;
    return (4 / 3) * 3.1416 * radius * radius * radius;
  }

  double mmToPixels(double mm, BuildContext context) {
    double dpi = MediaQuery.of(context).devicePixelRatio * 160;
    double inches = mm / 25.4;
    return inches * dpi;
  }
  Color? appBarColor;
  Future<void> _loadAppBarColor() async {
    appBarColor = await AppColorHelper.getAppBarColor();
    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadAppBarColor();
  }

  @override
  Widget build(BuildContext context) {
    double displaySize = mmToPixels(_diameter, context) / 2.4;
    double volume = calculateBeadVolume(_diameter);

    // Prepare the table rows
    List<DataRow> dataRows = [];

    for (int i = 1; i <= 50; i++) {
      bool isExpanded = _expandedIndex == i;

      // Main size row
      dataRows.add(
        DataRow(
          selected: (_diameter.toStringAsFixed(1) == i.toStringAsFixed(1)),
          onSelectChanged: (_) {
            setState(() {
              if (_expandedIndex == i) {
                _expandedIndex = null;
              } else {
                _expandedIndex = i;
              }
              _diameter = i.toDouble();
            });
          },
          cells: [
            DataCell(Text("$i")),
            DataCell(Text(i.toStringAsFixed(1))),
          ],
        ),
      );

      // If expanded, add sub sizes as separate rows indented
      if (isExpanded) {
        for (int j = 1; j <= 9; j++) {
          double subSize = i + j * 0.1;
          bool isSelected = (_diameter.toStringAsFixed(1) == subSize.toStringAsFixed(1));
          dataRows.add(
            DataRow(
              selected: isSelected,
              onSelectChanged: (_) {
                setState(() {
                  _diameter = subSize;
                });
              },
              cells: [
                DataCell(Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Text("${i}.${j}"),
                )),
                DataCell(Text(subSize.toStringAsFixed(1))),
              ],
            ),
          );
        }
      }
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: appBarColor ?? Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text("GB Bead Sizer", style:FontStyles.appbar_heading,),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 00.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Selected Diameter: ${_diameter.toStringAsFixed(1)} mm",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              flex: 3,
              child: Center(
                child: Container(
                  width: displaySize,
                  height: displaySize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.shade100,
                    border: Border.all(color: Colors.blueAccent, width: 2),
                  ),
                ),
              ),
            ),
            // Expanded(
            //   flex: 3,
            //   child: Center(
            //     child: Column(
            //       children: [
            //         Column(
            //           children: [
            //             Container(
            //               width: _diameter * 2,
            //               height: _diameter * 2,
            //               decoration: BoxDecoration(
            //                 shape: BoxShape.circle,
            //                 color: Colors.blue.withOpacity(0.2),
            //                 border: Border.all(color: Colors.blueAccent, width: 3),
            //                 boxShadow: [
            //                   BoxShadow(
            //                     color: Colors.blueAccent.withOpacity(0.5),
            //                     blurRadius: 10,
            //                     spreadRadius: 2,
            //                   ),
            //                 ],
            //               ),
            //               child: Center(
            //                 child: Text("",
            //                   // "${_diameter.toStringAsFixed(1)} mm",
            //                   style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            //                 ),
            //               ),
            //             ),
            //             SizedBox(height: 10),
            //             Center(
            //               child: Text(
            //                 "${_diameter.toStringAsFixed(1)} mm",
            //                 style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            //               ),
            //             ),
            //           ],
            //         ),
            //         SizedBox(height: 10),
            //       ],
            //     ),
            //   ),
            // ),
            Slider(
              min: 1,
              max: 50,
              value: _diameter,
              activeColor: Colors.blue,
              inactiveColor: Colors.grey[300],
              onChanged: (value) {
                setState(() {
                  _diameter = value;
                });
              },
            ),

            Expanded(
              flex: 4,
              child: Container(
                decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              blurRadius: 5,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: DataTable(
                    headingRowColor: MaterialStateColor.resolveWith((states) => Colors.blue.shade50),
                    columns: const [
                      DataColumn(
                          label: Text("Indian Size",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(
                          label: Text("Diameter (mm)",
                              style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: dataRows,
                  ),
                ),
              ),
            ),
            // Expanded(
            //   flex: 3,
            //   child: Padding(
            //
            //     padding: const EdgeInsets.symmetric(horizontal: 10), // Reduced unwanted space
            //     child: Container(
            //       decoration: BoxDecoration(
            //         borderRadius: BorderRadius.circular(10),
            //         color: Colors.white,
            //         boxShadow: [
            //           BoxShadow(
            //             color: Colors.grey.withOpacity(0.3),
            //             blurRadius: 5,
            //             spreadRadius: 1,
            //           ),
            //         ],
            //       ),
            //       child: SingleChildScrollView(
            //         child: DataTable(
            //           columnSpacing: 100.0, // Adjusts space between columns
            //           columns: [
            //             DataColumn(label: Text("Indian Size", style: TextStyle(fontWeight: FontWeight.bold))),
            //             DataColumn(label: Text("Diameter (mm)", style: TextStyle(fontWeight: FontWeight.bold))),
            //           ],
            //           rows: _sizeData.map((data) {
            //             return DataRow(
            //               cells: [
            //                 DataCell(Text(data["size"])),
            //                 DataCell(
            //                   Text(data["diameter"].toStringAsFixed(2)),
            //                   onTap: () {
            //                     setState(() {
            //                       _diameter = data["diameter"];
            //                     });
            //                   },
            //                 ),
            //               ],
            //             );
            //           }).toList(),
            //         ),
            //       ),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 50,
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          bottom: MediaQuery.of(context).padding.bottom,
          top: 8,
        ),
        // decoration: BoxDecoration(
        //   color: Colors.white,
        //   boxShadow: [
        //     BoxShadow(
        //       color: Colors.black12,
        //       blurRadius: 5,
        //       offset: Offset(0, -3),
        //     )
        //   ],
        // ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Text("Total Weight: ${getTotalWeight().toStringAsFixed(2)} gms",style: FontStyles.font16_bold),
            // //Text("Total Weight:", style: FontStyles.font16_bold),
            // // Text("${getTotalWeight().toStringAsFixed(3)} gms", style: FontStyles.font16_bold),
            // ElevatedButton(
            //   style: ElevatedButton.styleFrom(
            //     backgroundColor: Colors.blue[300],
            //     padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            //     shape: RoundedRectangleBorder(
            //       borderRadius: BorderRadius.circular(10),
            //     ),
            //   ),
            //   onPressed: () async {
            //     await showDialog(
            //       context: context,
            //       barrierDismissible: false,
            //       builder: (context) {
            //         return Dialog(
            //           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            //           elevation: 2,
            //           backgroundColor: Colors.white,
            //           //backgroundColor: const Color(0xFFF4F3FE), // Soft pastel background
            //           child: Padding(
            //             padding: const EdgeInsets.all(20),
            //             child: Column(
            //               mainAxisSize: MainAxisSize.min,
            //               children: [
            //                 const Icon(
            //                   Icons.mode_comment_outlined,
            //                   color: Color(0xFF6C63FF), // Elegant Indigo
            //                   size: 50,
            //                 ),
            //                 const SizedBox(height: 12),
            //                 const Text(
            //                   '📝 Enter Remarks',
            //                   style: TextStyle(
            //                     fontSize: 22,
            //                     fontWeight: FontWeight.bold,
            //                     color: Color(0xFF333366),
            //                   ),
            //                 ),
            //                 const SizedBox(height: 12),
            //                 TextField(
            //                   controller: _controller,
            //                   maxLines: 4,
            //                   decoration: InputDecoration(
            //                     hintText: 'Write your notes here...',
            //                     filled: true,
            //                     fillColor: Colors.white,
            //                     hintStyle: TextStyle(color: Colors.grey.shade500),
            //                     border: OutlineInputBorder(
            //                       borderRadius: BorderRadius.circular(12),
            //                       borderSide: const BorderSide(color: Color(0xFF6C63FF)),
            //                     ),
            //                     focusedBorder: OutlineInputBorder(
            //                       borderRadius: BorderRadius.circular(12),
            //                       borderSide:
            //                       const BorderSide(color: Color(0xFF6C63FF), width: 2),
            //                     ),
            //                   ),
            //                   style: const TextStyle(color: Color(0xFF333366)),
            //                 ),
            //                 const SizedBox(height: 20),
            //                 Row(
            //                   children: [
            //                     Expanded(
            //                       child: OutlinedButton(
            //                         onPressed: () => Navigator.of(context).pop(),
            //                         style: OutlinedButton.styleFrom(
            //                           foregroundColor: Colors.black87,
            //                           side: const BorderSide(color: Color(0xFF9999CC)),
            //                           shape: RoundedRectangleBorder(
            //                             borderRadius: BorderRadius.circular(10),
            //                           ),
            //                           padding: const EdgeInsets.symmetric(vertical: 14),
            //                         ),
            //                         child: Text("Cancel",style: FontStyles.font16_bold),
            //                       ),
            //                     ),
            //                     const SizedBox(width: 12),
            //                     Expanded(
            //                       child: ElevatedButton.icon(
            //                         onPressed: () {
            //                           _addOrder(_controller.text.trim());
            //                           Navigator.of(context).pop();
            //                         },
            //                         icon: const Icon(Icons.send_rounded, size: 18,color: Colors.white,),
            //                         label: Text("Submit",style: FontStyles.button),
            //                         style: ElevatedButton.styleFrom(
            //                           backgroundColor:Colors.blue,
            //                           foregroundColor: Colors.white,
            //                           shape: RoundedRectangleBorder(
            //                               borderRadius: BorderRadius.circular(10)),
            //                           padding: const EdgeInsets.symmetric(vertical: 14),
            //                         ),
            //                       ),
            //                     ),
            //                   ],
            //                 )
            //               ],
            //             ),
            //           ),
            //         );
            //       },
            //     );
            //   },
            //   child: Text("Submit", style: FontStyles.button),
            // ),
          ],
        ),
      ),
    );
  }
}