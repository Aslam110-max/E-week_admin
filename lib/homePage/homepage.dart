import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:eweek_admin/Colors/colors.dart';
import 'package:eweek_admin/Dimentions/dimention.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:lottie/lottie.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool eventsFinished = false;
  bool loadingHistory = false;
  bool loading = true;
  bool noData = true;
  Map pointsMap = {};
  late List allTeams;
  double eventTotalPoints = 0;
  late Map appDataMap;
  late Map eventsMap;
  late List eventsList;
  late List eWeekHistoryList;
  ScrollController controller = ScrollController();
  DatabaseReference database = FirebaseDatabase.instance.ref();
  double scale = 1;
  double topContainer = 0;
  late double heit1;
  late double heit2;
  late double heit3;
  late double heit4;
  late double heit5;
  String activatedYear = "";
  PlatformFile? eventImage;
  UploadTask? uploadTask;
  TextEditingController eventNameController = TextEditingController();
  TextEditingController eventPointsController = TextEditingController();
  Map teamPoits={};
  _selectAdImage() async {
    final result = await FilePicker.platform.pickFiles(
      allowedExtensions: ['jpg', 'png'],
      type: FileType.custom,
    );
    if (result == null) return;
    setState(() {
      eventImage = result.files.first;
    });
    _addFood(context);
  }

  Future<String> uploadFoodImage(
    String eventName,
  ) async {
    final path =
        'Eweek$activatedYear/eventImages/$eventName.${eventImage!.extension}';
    final file = File(eventImage!.path!);
    final ref = FirebaseStorage.instance.ref().child(path);
    uploadTask = ref.putFile(file);
    final snapshot = await uploadTask!.whenComplete(() {});
    final downloadUrl = await snapshot.ref.getDownloadURL();
    return downloadUrl;
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool updateLoading = false;

  @override
  void initState() {
    //sendPushNotification("title", "body");
    setInitialHeit();
    loadAppData();
    requestPermission();
    controller.addListener(() {
      double value = controller.offset / (Dimensions.height100 * 1.45);
      setState(() {
        topContainer = value;
      });
    });
    // TODO: implement initState
    super.initState();
  }
  /* Future<void> sendPushNotification(
     String title, String body) async {
    try {
      await http.post(Uri.parse('https://fcm.googleapis.com/fcm/send'),
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization':
                'key =AAAAFcK-XqM:APA91bHqLt7zHVPlwlayUY2-ZxSoWbMIhxrPkO2DwHMqlG38dvc9YB2ct_BRXsm8nt-r7Ekc9PCNPlluxVm6QJhzjBm__iWTdMugfEMHZC0XwmPB5NW4tmKNzfvGOsLiFImFP6UTUHFu'
          },
          body: jsonEncode(<String, dynamic>{
            'priority': 'high',
            'data': <String, dynamic>{
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'status': 'done',
              'body': '$body',
              'title': '$title',
            },
            "notification": <String, dynamic>{
              "title": "$title",
              "body": "$body",
              "android_channel_id": "EWeek"
            },
            "to": "/topics/EWeekNotification"
          }));
      print('done');
    } catch (e) {
      print('Error is $e');
    }}*/

  void setInitialHeit() {
    setState(() {
      heit1 = Dimensions.height100 * 0.7;
      heit2 = Dimensions.height100 * 0.7;
      heit3 = Dimensions.height100 * 0.7;
      heit4 = Dimensions.height100 * 0.7;
      heit5 = Dimensions.height100 * 0.7;
    });
  }

  List sortMap(Map map) {
    Map tempMap = Map.fromEntries(
        map.entries.toList()..sort((e1, e2) => e2.value.compareTo(e1.value)));

    return tempMap.keys.toList();
  }

  Future loadAppData() async {
    await database.child("History").once().then((value) {
      if (value.snapshot.value != null) {
        Map historyMap = value.snapshot.value as Map;
        eWeekHistoryList = historyMap.keys.toList();
        eWeekHistoryList.sort();
        //print(eWeekHistoryList);
      }
    });
    await database.child("AppData").child('activatedYear').once().then((value) {
      setState(() {
        activatedYear = "${value.snapshot.value}";
        print(activatedYear);
      });
    });
    await loadData();
  }

  Future<void> loadData() async {
    await database.child("Eweek$activatedYear").once().then((value) {
      if (value.snapshot.value != null) {
        appDataMap = value.snapshot.value as Map;
        if (appDataMap['events'] != null) {
          eventsMap = appDataMap['events'] as Map;
          eventsList = eventsMap.keys.toList();
          calculatePoints();
          setState(() {
            if (eventsList.length == appDataMap['totalEvents']) {
              eventsFinished = true;
            } else {
              eventsFinished = false;
            }
            noData = false;
          });
        } else {
          setState(() {
            noData = true;
          });
        }
      } else {
        setState(() {
          noData = true;
        });
      }
    });
    setState(() {
      loading = false;
      loadingHistory = false;
    });
    if (!noData) {
      setHeiyt();
    }
  }

  void calculatePoints() {
    pointsMap = {};
    eventTotalPoints = 0;
    for (String event in eventsList) {
      Map teamsPointsMap = eventsMap[event]['teamPoints'] as Map;
      List teamsList = teamsPointsMap.keys.toList();
      eventTotalPoints += eventsMap[event]['points'];
      for (String team in teamsList) {
        if (pointsMap[team] != null) {
          setState(() {
            pointsMap[team] = pointsMap[team] + teamsPointsMap[team];
          });
        } else {
          pointsMap[team] = teamsPointsMap[team];
        }
      }
    }
    setState(() {
      eventsList.sort();
      eventsList = eventsList.reversed.toList();
      pointsMap = Map.fromEntries(pointsMap.entries.toList()
        ..sort((e1, e2) => e2.value.compareTo(e1.value)));
      allTeams = pointsMap.keys.toList();
    });
    print(pointsMap);
    print(eventTotalPoints);
  }

  Future<void> requestPermission() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        provisional: false,
        sound: true);
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      print('User granted permission provisional');
    } else {
      print('User declined or has not accepted permission');
    }
  }

  Future<void> setHeiyt() async {
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      heit1 = (pointsMap[allTeams[0]] / pointsMap[allTeams[0]]) *
          Dimensions.height100 *
          2.5;
      heit2 = (pointsMap[allTeams[1]] / pointsMap[allTeams[0]]) *
          Dimensions.height100 *
          2.5;
      heit3 = (pointsMap[allTeams[2]] / pointsMap[allTeams[0]]) *
          Dimensions.height100 *
          2.5;
      heit4 = (pointsMap[allTeams[3]] / pointsMap[allTeams[0]]) *
          Dimensions.height100 *
          2.5;
      heit5 = (pointsMap[allTeams[4]] / pointsMap[allTeams[0]]) *
          Dimensions.height100 *
          2.5;
    });
  }

  bool scollerFunction(int i) {
    if (topContainer > 0.4) {
      scale = i + 3.7 - topContainer;

      if (scale < 0) {
        scale = 0;
      } else if (scale > 1) {
        scale = 1;
      }
    }
    return true;
  }

  Widget build(BuildContext context) {
    return loading
        ? Center(
            child: LoadingAnimationWidget.beat(
                color: Color.fromARGB(255, 120, 8, 0),
                size: Dimensions.height100 * 0.3)

            /*flickr(
          leftDotColor: Color.fromARGB(255, 255, 255, 255),
          rightDotColor: Color.fromARGB(255, 98, 0, 0),
          size: Dimensions.height100*0.3,
        )*/
            )
        : Stack(
            children: [
              Scaffold(
                  floatingActionButton: FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        teamPoits={};
                        eventImage=null;
                      });
                      _addFood(context);
                    },
                    child: Icon(
                      Icons.add,
                      color: Colors.black,
                    ),
                    backgroundColor: Colors.white,
                  ),
                  appBar: AppBar(
                    elevation: 0,
                    actions: [
                      IconButton(
                        onPressed: () {
                          showCupertinoDialog(
                              context: context, builder: alertDialog);
                        },
                        icon: Icon(Icons.info_outline_rounded),
                        color: ColorClass.mainColor,
                      )
                    ],
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.transparent,
                    title: eWeekHistoryList.length > 1
                        ? DropdownButton<String>(
                            dropdownColor: Colors.black,
                            iconSize: Dimensions.height10 * 2,
                            underline: SizedBox(),
                            value: activatedYear,
                            items: eWeekHistoryList.map((year) {
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
                                activatedYear = "$year";
                                loadingHistory = true;
                              });
                              setInitialHeit();
                              await loadData();
                            })
                        : Text(
                            "E-Week $activatedYear",
                            style: TextStyle(
                                color: ColorClass.mainColor,
                                fontSize: Dimensions.height10 * 1.1),
                          ),
                  ),
                  backgroundColor: Colors.black,
                  body: noData
                      ? noDataAnimation()
                      : RefreshIndicator(
                          color: Color.fromARGB(255, 140, 11, 2),
                          onRefresh: () async {
                            await loadData();
                            await loadAppData();
                          },
                          child: CustomScrollView(
                            physics: const BouncingScrollPhysics(),
                            controller: controller,
                            slivers: [
                              SliverAppBar(
                                expandedHeight: Dimensions.height100 * 4,
                                backgroundColor: Colors.transparent,
                                flexibleSpace: FlexibleSpaceBar(
                                  background: Stack(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(
                                            top: Dimensions.height10),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            if (allTeams[3] != null)
                                              threeDBox(
                                                  heit4,
                                                  appDataMap['teams']
                                                      [allTeams[3]]['imageUrl'],
                                                  allTeams[3],
                                                  pointsMap[allTeams[3]],
                                                  3),
                                            if (allTeams[1] != null)
                                              threeDBox(
                                                  heit2,
                                                  appDataMap['teams']
                                                      [allTeams[1]]['imageUrl'],
                                                  allTeams[1],
                                                  pointsMap[allTeams[1]],
                                                  1),
                                            if (allTeams[0] != null)
                                              threeDBox(
                                                  heit1,
                                                  appDataMap['teams']
                                                      [allTeams[0]]['imageUrl'],
                                                  allTeams[0],
                                                  pointsMap[allTeams[0]],
                                                  0),
                                            if (allTeams[2] != null)
                                              threeDBox(
                                                  heit3,
                                                  appDataMap['teams']
                                                      [allTeams[2]]['imageUrl'],
                                                  allTeams[2],
                                                  pointsMap[allTeams[2]],
                                                  2),
                                            if (allTeams[4] != null)
                                              threeDBox(
                                                  heit5,
                                                  appDataMap['teams']
                                                      [allTeams[4]]['imageUrl'],
                                                  allTeams[4],
                                                  pointsMap[allTeams[4]],
                                                  4),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          SizedBox(
                                            height: Dimensions.height100 * 2.8,
                                          ),
                                          percentageIndicator()
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              SliverToBoxAdapter(
                                child: Column(
                                  children: [
                                    SizedBox(
                                      height: Dimensions.height10,
                                    ),
                                    for (int i = 0; i < eventsList.length; ++i)
                                      if (scollerFunction(i))
                                        Padding(
                                          padding: EdgeInsets.only(
                                              bottom: Dimensions.height10 * 2),
                                          child: Opacity(
                                            opacity: scale,
                                            child: Transform(
                                              transform: Matrix4.identity()
                                                ..scale(scale, scale),
                                              alignment: Alignment.bottomCenter,
                                              child: Align(
                                                  heightFactor: 0.9,
                                                  alignment:
                                                      Alignment.topCenter,
                                                  child: listViewWidget(i)),
                                            ),
                                          ),
                                        )
                                  ],
                                ),
                              )
                            ],
                          ),
                        )),
              if (loadingHistory)
                Scaffold(
                  backgroundColor: Color.fromARGB(193, 0, 0, 0),
                  body: Center(
                      child: LoadingAnimationWidget.beat(
                          color: Color.fromARGB(255, 120, 8, 0),
                          size: Dimensions.height100 * 0.3)),
                )
            ],
          );
  }

  Widget noDataAnimation() {
    return Center(
      child: Lottie.asset('images/noData.json', frameRate: FrameRate(144)),
    );
  }

  Widget listViewWidget(int i) {
    return StatefulBuilder(builder: (context, setState) {
      return Container(
        decoration: BoxDecoration(
            image: DecorationImage(
                image: CachedNetworkImageProvider(
                    eventsMap[eventsList[i]]['imageUrl']),
                fit: BoxFit.fill),
            color: Colors.black,
            borderRadius: BorderRadius.circular(Dimensions.height10),
            border: Border.all(
                color: Color.fromARGB(255, 129, 0, 0),
                width: Dimensions.height10 * 0.2)),
        height: Dimensions.height100 * 1.5,
        width: Dimensions.width150 * 1.8,
        child: Stack(
          children: [
            Center(
              child: Container(
                height: Dimensions.height100 * 1.47,
                width: Dimensions.width150 * 1.77,
                decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(Dimensions.height10 * 0.8),
                    gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 0, 0, 0),
                          Color.fromARGB(142, 158, 158, 158)
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter)),
              ),
            ),
            Center(
              child: Container(
                height: Dimensions.height100 * 1.38,
                width: Dimensions.width150 * 1.77,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(Dimensions.height10 * 0.8),
                ),
                child: Padding(
                  padding: EdgeInsets.all(Dimensions.height10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${eventsMap[eventsList[i]]['name']}",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: Dimensions.height10 * 1.8,
                                  fontWeight: FontWeight.w700),
                            ),
                            SizedBox(
                              height: Dimensions.height10 * 0.1,
                            ),
                            Text(
                              "Points for ${eventsMap[eventsList[i]]['points']}",
                              style: TextStyle(
                                color: Color.fromARGB(255, 255, 255, 255),
                                fontSize: Dimensions.height10 * 0.7,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        child: Column(
                          children: [
                            for (int j = 0;
                                j <
                                    (sortMap(eventsMap[eventsList[i]]
                                            ['teamPoints'] as Map))
                                        .length;
                                ++j)
                              Align(
                                heightFactor: 0.8,
                                alignment: Alignment.topCenter,
                                child: Container(
                                  width: Dimensions.width150 * 1.6 -
                                      j * Dimensions.height10,
                                  height: Dimensions.height10 * 2,
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Color.fromARGB(
                                              255, 196, 157, 157)),
                                      //boxShadow: [BoxShadow(color: Color.fromARGB(255, 203, 102, 2),offset: Offset(0, 2),blurRadius: Dimensions.height10*0.2)],
                                      borderRadius: BorderRadius.circular(
                                          Dimensions.height10),
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color.fromARGB(200, 84, 31, 31),
                                          Color.fromARGB(200, 0, 0, 0),
                                          Color.fromARGB(200, 84, 31, 31),
                                        ],
                                      )),
                                  child: Center(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                          left: Dimensions.height10,
                                          right: Dimensions.height10),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          SizedBox(
                                            child: Row(
                                              children: [
                                                Container(
                                                  height:
                                                      Dimensions.height10 * 1.4,
                                                  width:
                                                      Dimensions.height10 * 1.4,
                                                  decoration: BoxDecoration(
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                          color: Colors.white)),
                                                  child: Center(
                                                    child: Text(
                                                      "${j + 1}",
                                                      style: TextStyle(
                                                          fontSize: Dimensions
                                                                  .height10 *
                                                              0.8,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Colors.white),
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: Dimensions.width10,
                                                ),
                                                Text(
                                                  "${sortMap(eventsMap[eventsList[i]]['teamPoints'] as Map)[j]}",
                                                  style: TextStyle(
                                                      color: Color.fromARGB(
                                                          255, 255, 255, 255),
                                                      fontSize:
                                                          Dimensions.height10 *
                                                              0.8),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            "Points: ${(eventsMap[eventsList[i]]['teamPoints'] as Map)[sortMap(eventsMap[eventsList[i]]['teamPoints'] as Map)[j]]}",
                                            style: TextStyle(
                                                color: Color.fromARGB(
                                                    255, 255, 255, 255),
                                                fontSize:
                                                    Dimensions.height10 * 0.8),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              IconButton(
                  onPressed: () {
                    deleteDialogBox(i);
                    print("object");
                  },
                  icon: Icon(Icons.remove_circle,
                      color: const Color.fromARGB(255, 87, 6, 0)))
            ]),
          ],
        ),
      );
    });
  }

  Widget threeDBox(
      double heit, String imageUrl, String name, int points, int index) {
    return Container(
      color: Colors.transparent,
      height: Dimensions.height100 * 3.15,
      width: Dimensions.height100 * 0.54,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              Column(
                children: [
                  SizedBox(
                    height: Dimensions.height10 * 3.3,
                  ),
                  Center(
                    child: Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0035)
                        ..rotateX(-1.4),
                      alignment: Alignment.center,
                      child: Container(
                        height: Dimensions.height100 * 0.5,
                        width: Dimensions.height100 * 0.5,
                        decoration: const BoxDecoration(
                            gradient: LinearGradient(
                                colors: [
                              Color.fromARGB(255, 84, 31, 31),
                              Color.fromARGB(255, 0, 0, 0)
                            ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter)),
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    height: Dimensions.height100 * 0.54,
                    width: Dimensions.height100 * 0.7 * 21 / 20,
                    child: Stack(
                      children: [
                        Center(
                          child: Container(
                            height: Dimensions.height10 * 1.5,
                            width: Dimensions.height10 * 1.5,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                      color: eventsFinished && index == 0
                                          ? Color.fromARGB(255, 255, 255, 255)
                                          : Color.fromARGB(255, 255, 223, 15),
                                      spreadRadius: eventsFinished && index == 0
                                          ? Dimensions.height10
                                          : Dimensions.height10 * 0.5,
                                      blurRadius: eventsFinished && index == 0
                                          ? Dimensions.height10 * 3
                                          : Dimensions.height10 * 4)
                                ]),
                          ),
                        ),
                        CachedNetworkImage(imageUrl: imageUrl),
                        Column(
                          children: [
                            SizedBox(
                              height: Dimensions.height10 * 4.25,
                            ),
                            Center(
                                child: Text(
                              name,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: Dimensions.height10 * 0.8,
                                  fontWeight: FontWeight.w600),
                            )),
                          ],
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: Dimensions.height10 * 0.85,
                  ),
                  Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      height: heit,
                      width: Dimensions.height100 * 0.55,
                      decoration: const BoxDecoration(
                          gradient: LinearGradient(
                              colors: [
                            Color.fromARGB(255, 80, 18, 18),
                            Color.fromARGB(255, 0, 0, 0)
                          ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter)),
                      child: Padding(
                        padding: EdgeInsets.all(Dimensions.height10 * 0.5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              "$points",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: Dimensions.height10 * 1.3,
                                  fontWeight: FontWeight.w700,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black,
                                      offset:
                                          Offset(Dimensions.height10 * 0.1, 3),
                                      blurRadius: Dimensions.height10 * 0.5,
                                    )
                                  ]),
                            ),
                            Text(
                              "Points",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: Dimensions.height10 * 0.5,
                              ),
                            ),
                            if (eventsFinished && index == 0)
                              Text(
                                "Winner!",
                                style: TextStyle(
                                    color: Color.fromARGB(255, 255, 255, 255),
                                    fontSize: Dimensions.height10 * 1.2,
                                    fontWeight: FontWeight.w700,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black,
                                        offset: Offset(
                                            Dimensions.height10 * 0.1, 3),
                                        blurRadius: Dimensions.height10 * 0.5,
                                      )
                                    ]),
                              )
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget percentageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularPercentIndicator(
          animation: true,
          animationDuration: 1000,
          radius: Dimensions.height100 * 0.5,
          lineWidth: Dimensions.height10 * 0.6,
          percent: eventsList.length / appDataMap['totalEvents'],
          center: Text(
            "${((eventsList.length / appDataMap['totalEvents']) * 100).round()}%",
            style: TextStyle(
                color: Colors.white,
                fontSize: Dimensions.height10 * 1.3,
                fontWeight: FontWeight.w600),
          ),
          backgroundColor: Color.fromARGB(255, 68, 67, 67),
          progressColor: Color.fromARGB(255, 116, 1, 1),
        ),
        SizedBox(
          width: Dimensions.width10 * 4,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: Dimensions.width10 * 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Events:",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: Dimensions.height10,
                        fontWeight: FontWeight.w700),
                  ),
                  Text(
                    "${appDataMap['totalEvents']}",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: Dimensions.height10,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: Dimensions.width10 * 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Completed:",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: Dimensions.height10,
                        fontWeight: FontWeight.w700),
                  ),
                  Text(
                    "${eventsList.length}",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: Dimensions.height10,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget alertDialog(BuildContext context) => CupertinoAlertDialog(
        title: Text("Welcome!"),
        content: Text("Developed by Aslam NM -E20"),
        actions: [
          CupertinoDialogAction(
            child: Text(
              "Ok",
              style: TextStyle(
                  color: const Color.fromARGB(255, 128, 9, 0),
                  fontWeight: FontWeight.w500),
            ),
            onPressed: () => Navigator.pop(context),
          )
        ],
      );
  deleteDialogBox(int i) {
    bool deleting = false;
    showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              elevation: 0,
              backgroundColor: Colors.transparent,
              content: Container(
                height: 200,
                child: Column(
                  children: [
                    Text(
                      'Do you want to delete?',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: Dimensions.height10 * 1.5),
                    ),
                    !deleting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    'No',
                                    style: TextStyle(
                                        fontSize: Dimensions.height10 * 1.5,
                                        color: Colors.white54),
                                  )),
                              TextButton(
                                  onPressed: () async {
                                    setState(() {
                                      deleting = true;
                                    });
                                    DatabaseReference database =
                                        FirebaseDatabase.instance.ref();
                                    database
                                        .child("Eweek$activatedYear")
                                        .child('events')
                                        .child(
                                            "${eventsMap[eventsList[i]]['name']}")
                                        .set(null);

                                    /* try {
                                           await FirebaseStorage.instance
                                        .ref(
                                            'Eweek$activatedYear/eventImages/${eventsMap[eventsList[i]]['name']}.jpg')
                                        .delete();
                                        } catch (e) {
                                           await FirebaseStorage.instance
                                        .ref(
                                            'Eweek$activatedYear/eventImages/${eventsMap[eventsList[i]]['name']}.png')
                                        .delete();
                                        }*/
                                    await loadData();
                                    await loadAppData();

                                    this.setState(() {
                                      setState(() {
                                        deleting = false;
                                      });
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: Text(
                                    'yes',
                                    style: TextStyle(
                                        fontSize: Dimensions.height10 * 1.5,
                                        color: Colors.red[700]),
                                  )),
                            ],
                          )
                        : Text(
                            'Deleting',
                            style: TextStyle(color: ColorClass.mainColor),
                          )
                  ],
                ),
              ),
            );
          });
        });
  }

  _addFood(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(builder: (context, setState) {
          return AlertDialog(
            title: const Text(
              'Add Food',
              style: TextStyle(fontSize: 20),
            ),
            actions: [
              Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                              onPressed: () {
                                _selectAdImage();
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.photo)),
                          if (eventImage != null)
                            Expanded(
                                child: Text(
                              eventImage!.name,
                              overflow: TextOverflow.ellipsis,
                            ))
                          else
                            const Text('no Selected image'),
                        ],
                      ),
                      TextFormField(
                          validator: (val) {
                            if (val!.isEmpty) return "Enter Event Name";
                            return null;
                          },
                          decoration: InputDecoration(hintText: "Event Name"),
                          controller: eventNameController),
                      TextFormField(
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (val!.isEmpty) return "Event maximum ponits";
                            return null;
                          },
                          decoration: InputDecoration(
                            hintText: "Event points",
                          ),
                          controller: eventPointsController),
                      for (String team
                          in (appDataMap['teams'] as Map).keys.toList())
                        TextFormField(
                          onChanged: (points){
                           if(points!=""){
                             this.setState(() {
                              setState((){
                                teamPoits[team]=int.parse(points);
                                print(teamPoits.length);
                              });
                            });
                           }else{
                            this.setState(() {
                              setState((){
                                teamPoits.remove(team);
                                
                              });});
                           }
                          },
                          keyboardType: TextInputType.number,
                          validator: (val) {
                            if (val!.isEmpty) return "Enter team points";
                            return null;
                          },
                          decoration: InputDecoration(hintText: team),
                        ),
                      TextButton(
                          onPressed: () async {
                            if (_formKey.currentState!.validate()&& teamPoits.length==(appDataMap['teams'] as Map).keys.toList().length && !updateLoading&&eventImage!=null) {
                              this.setState(() {
                                setState(() {
                                  updateLoading = true;
                                });
                              });
                              String dateAndTimeId =
                                  DateFormat('yyyy-MM-dd kk:mm:ss')
                                      .format(DateTime.now())
                                      .replaceAll(RegExp('[^A-Za-z0-9]'), '');
                              DatabaseReference database =
                                  FirebaseDatabase.instance.ref();
                              String ImageUrl = await uploadFoodImage(
                                eventNameController.text,
                              );
                              await database
                                  .child("Eweek$activatedYear")
                                  .child('events')
                                  .update({
                                dateAndTimeId: {
                                  'imageUrl': ImageUrl,
                                  'name': eventNameController.text,
                                  'points':{
                                     for (String team
                          in (appDataMap['teams'] as Map).keys.toList())
                          team:teamPoits[team]
                                  }
                                }
                              });
                              this.setState(() {
                                setState(() {
                                  updateLoading = false;
                                });
                              });
                              Navigator.pop(context);
                            }
                          },
                          child: Text(
                            updateLoading ? 'Adding' : 'Add',
                            style: TextStyle(
                                fontSize: 20, color: ColorClass.mainColor),
                          ))
                    ],
                  ))
            ],
          );
        });
      },
    );
  }
}
