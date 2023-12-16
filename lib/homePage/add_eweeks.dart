
// ignore_for_file: must_be_immutable

import 'package:eweek_admin/Colors/colors.dart';
import 'package:eweek_admin/Dimentions/dimention.dart';
import 'package:flutter/material.dart';

class AddEWeeks extends StatefulWidget {
  static late List eventHistroryList;
  static late String currentYear;
   AddEWeeks({super.key,required List eHist,required String currentY}){
    eventHistroryList = eHist;
    currentYear = currentY;
   }

  @override
  State<AddEWeeks> createState() => _AddEWeeksState();
}

class _AddEWeeksState extends State<AddEWeeks> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
           DropdownButton<String>(
                            dropdownColor: Colors.black,
                            iconSize: Dimensions.height10 * 2,
                            underline: SizedBox(),
                            value: AddEWeeks.currentYear,
                            items: AddEWeeks.eventHistroryList.map((year) {
                              return DropdownMenuItem<String>(
                                value: year,
                                child: Text(
                                  "E-Week $year",
                                  style: TextStyle(
                                      color: ColorClass.mainColor,
                                      fontSize: Dimensions.height10 * 1.1),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? year) async {
                              setState(() {
                                AddEWeeks.currentYear = "$year";
                               
                              });
                             
                            })
        ],
      ),
    );
  }
}