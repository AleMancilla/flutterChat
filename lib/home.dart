import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'main.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_demo/chat.dart';
import 'package:flutter_chat_demo/const.dart';
import 'package:flutter_chat_demo/settings.dart';
import 'package:flutter_chat_demo/widget/full_photo.dart';
import 'package:flutter_chat_demo/widget/loading.dart';
import 'package:flutter_datetime_picker/flutter_datetime_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/services.dart';

FirebaseFirestore firestore = FirebaseFirestore.instance;

class HomeScreen extends StatefulWidget {
  final String currentUserId;

  HomeScreen({Key key, @required this.currentUserId}) : super(key: key);

  @override
  State createState() => HomeScreenState(currentUserId: currentUserId);
}

class HomeScreenState extends State<HomeScreen> {
  HomeScreenState({@required this.currentUserId});
  Key key = UniqueKey();

  void restartApp() {
    setState(() {
      key = UniqueKey();
      _currentIndex = 0;
    });
  }
  final String currentUserId;
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging();
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final GoogleSignIn googleSignIn = GoogleSignIn();

  bool isLoading = false;
  List<Choice> choices = const <Choice>[
    const Choice(title: 'Configuraciones', icon: Icons.settings),
    const Choice(title: 'Desconectate', icon: Icons.exit_to_app),
  ];
  SharedPreferences prefs;
  String photoUrl = '';
  @override
  void initState() {
    super.initState();
    registerNotification();
    configLocalNotification();
    readLocal();
  }
  void readLocal() async {
    prefs = await SharedPreferences.getInstance();
    // id = prefs.getString('id') ?? '';
    // nickname = prefs.getString('nickname') ?? '';
    // aboutMe = prefs.getString('aboutMe') ?? '';
    photoUrl = prefs.getString('photoUrl') ?? '';

    // controllerNickname = TextEditingController(text: nickname);
    // controllerAboutMe = TextEditingController(text: aboutMe);

    // Force refresh input
    setState(() {});
  }
  void registerNotification() {
    firebaseMessaging.requestNotificationPermissions();

    firebaseMessaging.configure(onMessage: (Map<String, dynamic> message) {
      print('onMessage: $message');
      Platform.isAndroid
          ? showNotification(message['notification'])
          : showNotification(message['aps']['alert']);
      return;
    }, onResume: (Map<String, dynamic> message) {
      print('onResume: $message');
      return;
    }, onLaunch: (Map<String, dynamic> message) {
      print('onLaunch: $message');
      return;
    });

    firebaseMessaging.getToken().then((token) {
      print('token: $token');
      FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .update({'pushToken': token});
    }).catchError((err) {
      Fluttertoast.showToast(msg: err.message.toString());
    });
  }

  void configLocalNotification() {
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = new IOSInitializationSettings();
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void onItemMenuPress(Choice choice) {
    if (choice.title == 'Desconectate') {
      handleSignOut();
    } else {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => ChatSettings(currentId: this.widget.currentUserId,)));
    }
  }

  void showNotification(message) async {
    var androidPlatformChannelSpecifics = new AndroidNotificationDetails(
      Platform.isAndroid
          ? 'com.flutter.proyectochat'
          : 'com.duytq.flutterchatdemo',
      'Flutter chat demo',
      'Tu canal descripcion',
      playSound: true,
      enableVibration: true,
      importance: Importance.Max,
      priority: Priority.High,
    );
    var iOSPlatformChannelSpecifics = new IOSNotificationDetails();
    var platformChannelSpecifics = new NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);

    print(message);
//    print(message['body'].toString());
//    print(json.encode(message));

    await flutterLocalNotificationsPlugin.show(0, message['title'].toString(),
        message['body'].toString(), platformChannelSpecifics,
        payload: json.encode(message));

//    await flutterLocalNotificationsPlugin.show(
//        0, 'plain title', 'plain body', platformChannelSpecifics,
//        payload: 'item x');
  }

  Future<bool> onBackPress() {
    openDialog();
    return Future.value(false);
  }

  Future<Null> openDialog() async {
    switch (await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            contentPadding:
                EdgeInsets.only(left: 0.0, right: 0.0, top: 0.0, bottom: 0.0),
            children: <Widget>[
              Container(
                color: themeColor,
                margin: EdgeInsets.all(0.0),
                padding: EdgeInsets.only(bottom: 10.0, top: 10.0),
                height: 100.0,
                child: Column(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.exit_to_app,
                        size: 30.0,
                        color: Colors.white,
                      ),
                      margin: EdgeInsets.only(bottom: 10.0),
                    ),
                    Text(
                      'Salir de la app',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Estas seguro que quieres salir?',
                      style: TextStyle(color: Colors.white70, fontSize: 14.0),
                    ),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 0);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.cancel,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      'CANCEL',
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 1);
                },
                child: Row(
                  children: <Widget>[
                    Container(
                      child: Icon(
                        Icons.check_circle,
                        color: primaryColor,
                      ),
                      margin: EdgeInsets.only(right: 10.0),
                    ),
                    Text(
                      'SI',
                      style: TextStyle(
                          color: primaryColor, fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
            ],
          );
        })) {
      case 0:
        break;
      case 1:
        exit(0);
        break;
    }
  }

  Future<Null> handleSignOut() async {
    this.setState(() {
      isLoading = true;
    });

    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();

    this.setState(() {
      isLoading = false;
    });

    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MyApp()),
        (Route<dynamic> route) => false);
  }

  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: key,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'MASCOTAS',
            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          actions: <Widget>[
            CircleAvatar(
              backgroundImage: photoUrl!=""? NetworkImage(photoUrl):AssetImage("images/icono.png"),
              backgroundColor: Colors.transparent,
              radius: 20.0,
            ),
            PopupMenuButton<Choice>(
              onSelected: onItemMenuPress,
              itemBuilder: (BuildContext context) {
                return choices.map((Choice choice) {
                  return PopupMenuItem<Choice>(
                      value: choice,
                      child: Row(
                        children: <Widget>[
                          Icon(
                            choice.icon,
                            color: primaryColor,
                          ),
                          Container(
                            width: 10.0,
                          ),
                          Text(
                            choice.title,
                            style: TextStyle(color: primaryColor),
                          ),
                        ],
                      ));
                }).toList();
              },
            ),
          ],
        ),
        body: WillPopScope(
          child: Stack(
            children: <Widget>[
              // List
              // Container(
              //   child: StreamBuilder(
              //     stream:
              //         FirebaseFirestore.instance.collection('users').snapshots(),
              //     builder: (context, snapshot) {
              //       if (!snapshot.hasData) {
              //         return Center(
              //           child: CircularProgressIndicator(
              //             valueColor: AlwaysStoppedAnimation<Color>(themeColor),
              //           ),
              //         );
              //       } else {
              //         return ListView.builder(
              //           padding: EdgeInsets.all(10.0),
              //           itemBuilder: (context, index) =>
              //               buildItem(context, snapshot.data.documents[index]),
              //           itemCount: snapshot.data.documents.length,
              //         );
              //       }
              //     },
              //   ),
              // ),

              SafeArea(
                top: false,
                child: IndexedStack(
                  index: _currentIndex,
                  children: allDestinations.map<Widget>((Destination destination) {
                    print(_currentIndex);
                    return bodyPage(_currentIndex);
                    // return DestinationView(destination: destination);
                  }).toList(),
                ),
              ),

              // Loading
              Positioned(
                child: isLoading ? const Loading() : Container(),
              )
            ],
          ),
          onWillPop: onBackPress,
        ),
        // body:  SafeArea(
        //   top: false,
        //   child: IndexedStack(
        //     index: _currentIndex,
        //     children: allDestinations.map<Widget>((Destination destination) {
        //       return DestinationView(destination: destination);
        //     }).toList(),
        //   ),
        // ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (int index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: allDestinations.map((Destination destination) {
            return BottomNavigationBarItem(
              icon: Icon(destination.icon),
              backgroundColor: destination.color,
              title: Text(destination.title)
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget buildItem(BuildContext context, DocumentSnapshot document) {
    if (document.data()['id'] == currentUserId) {
      return Container();
    } else {
      return Container(
        child: FlatButton(
          child: Row(
            children: <Widget>[
              Material(
                child: document.data()['photoUrl'] != null
                    ? CachedNetworkImage(
                        placeholder: (context, url) => Container(
                          child: CircularProgressIndicator(
                            strokeWidth: 1.0,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(themeColor),
                          ),
                          width: 50.0,
                          height: 50.0,
                          padding: EdgeInsets.all(15.0),
                        ),
                        imageUrl: document.data()['photoUrl'],
                        width: 50.0,
                        height: 50.0,
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        Icons.account_circle,
                        size: 50.0,
                        color: greyColor,
                      ),
                borderRadius: BorderRadius.all(Radius.circular(25.0)),
                clipBehavior: Clip.hardEdge,
              ),
              Flexible(
                child: Container(
                  child: Column(
                    children: <Widget>[
                      Container(
                        child: Text(
                          'Nickname: ${document.data()['nickname']}',
                          style: TextStyle(color: primaryColor),
                        ),
                        alignment: Alignment.centerLeft,
                        margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 5.0),
                      ),
                      Container(
                        child: Text(
                          'Acerca de mi: ${document.data()['aboutMe'] ?? 'Not available'}',
                          style: TextStyle(color: primaryColor),
                        ),
                        alignment: Alignment.centerLeft,
                        margin: EdgeInsets.fromLTRB(10.0, 0.0, 0.0, 0.0),
                      )
                    ],
                  ),
                  margin: EdgeInsets.only(left: 20.0),
                ),
              ),
            ],
          ),
          onPressed: () {

            // print("""
            // esto manda##
            // ${document.id} --- ${ document.data()['userId']}
            
            // """);
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Chat(
                          peerId: document.data()['userId'],
                          peerAvatar: document.data()['photoUrl'],
                        )));
          },
          color: greyColor2,
          padding: EdgeInsets.fromLTRB(25.0, 10.0, 25.0, 10.0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
        margin: EdgeInsets.only(bottom: 10.0, left: 5.0, right: 5.0),
      );
    }
  }

  Widget bodyPage(int i){
    switch (i) {
      case 0:
      return PageListMascotas();
        // return Container(
        //   color: Colors.orange,
        //   child: Center(
        //     child: Text("PAGINA INICIO"),
        //   ),
        // );
        break;
      case 1:
      return PageMapa();
        // return Container(
        //   color: Colors.blue,
        //     child: Center(
        //       child: Text("PAGINA DE MAPA"),
        //     ),
        //   );
        break;
      case 2:
        return PublicarMascota(currentUserId: this.widget.currentUserId,);
        // return Container(
        //   color: Colors.green,
        //   child: Center(
        //       child: Text("PUBLICAR MASCOTA PERDIDA"),
        //     ),
        // );
        break;
      case 3:
        return SettingsScreen(currentId: this.widget.currentUserId);
      // Navigator.push(
      //     context, MaterialPageRoute(builder: (context) => ChatSettings()));
        // return Container(color: Colors.pink,);
        break;
      case 4:
        return PageListMisMascotas(currentUserId: this.widget.currentUserId);
      // Navigator.push(
      //     context, MaterialPageRoute(builder: (context) => ChatSettings()));
        // return Container(color: Colors.pink,);
        break;
      default:
        return Container(color: Colors.white,);
    }
  }
}

class Choice {
  const Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}


//////////////
///
class Destination {
  const Destination(this.title, this.icon, this.color);
  final String title;
  final IconData icon;
  final MaterialColor color;
}

const List<Destination> allDestinations = <Destination>[
  Destination('Inicio', Icons.home, Colors.teal),
  Destination('Mapa', Icons.location_on, Colors.cyan),
  Destination('Publicar', Icons.add, Colors.blue),
  Destination('Configuracion', Icons.face, Colors.orange),
  Destination('Mios', Icons.edit, Colors.green),
];



class DestinationView extends StatefulWidget {
  const DestinationView({ Key key, this.destination }) : super(key: key);

  final Destination destination;

  @override
  _DestinationViewState createState() => _DestinationViewState();
}

class _DestinationViewState extends State<DestinationView> {
  TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: 'sample text: ${widget.destination.title}',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.destination.title} Text'),
        backgroundColor: widget.destination.color,
      ),
      backgroundColor: widget.destination.color[100],
      body: Container(
        padding: const EdgeInsets.all(32.0),
        alignment: Alignment.center,
        child: TextField(controller: _textController),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

/////////////////////////////
///[PAGE ADD PERDIDO]

class PublicarMascota extends StatefulWidget {
  final String currentUserId;

  const PublicarMascota({@required this.currentUserId}) ;
  @override
  _PublicarMascotaState createState() => _PublicarMascotaState();
}

class _PublicarMascotaState extends State<PublicarMascota> {

  TextStyle styleText = TextStyle(fontSize: 16,fontWeight: FontWeight.w500);

  String _chosenValue;

  bool cat = false;
  bool dog = false;
  bool other = false;

  bool macho = false;
  bool hembra = false;

  String estadoMascota = "";
  String fechaEstado = "--/--/----";

  String horaEstado = "00:00";

  TextEditingController controllerDirecction;
  TextEditingController controllerDescription;
  TextEditingController controllerNameProp;
  TextEditingController controllerNumberProp;

  @override
  void initState() {
    super.initState();
    controllerDirecction = new TextEditingController();
    controllerDescription = new TextEditingController();
    controllerNameProp = new TextEditingController();
    controllerNumberProp = new TextEditingController();
    readLocalization();

  }

  
  Position position;
  GoogleMapController mapController;
  List<Placemark> placemarks;
  void readLocalization() async{
    try {
      position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      positionMap = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 16
      );
        _obtenerDireccion(position.latitude, position.longitude);
      // setState(() async{
      // });
      _moveTo(positionMap);
    } catch (e) {
    }
  }
  String ciudad = "";
  String direccion = "";
  _obtenerDireccion(double lat, double long)async{
    placemarks = await placemarkFromCoordinates(lat,long);
      // print(" placemarks[0].administrativeArea == ${placemarks[0].administrativeArea}");
      // print(" placemarks[0].country == ${placemarks[0].country}");
      // print(" placemarks[0].isoCountryCode == ${placemarks[0].isoCountryCode}");
      // print(" placemarks[0].locality == ${placemarks[0].locality}");
      // print(" placemarks[0].name == ${placemarks[0].name}");
      // print(" placemarks[0].postalCode == ${placemarks[0].postalCode}");
      // print(" placemarks[0].street == ${placemarks[0].street}");
      // print(" placemarks[0].subAdministrativeArea == ${placemarks[0].subAdministrativeArea}");
      // print(" placemarks[0].subLocality == ${placemarks[0].subLocality}");
      // print(" placemarks[0].subThoroughfare == ${placemarks[0].subThoroughfare}");
      // print(" placemarks[0].thoroughfare == ${placemarks[0].thoroughfare}");
      ciudad = placemarks[0].locality;
      direccion = placemarks[0].street;
      controllerDirecction.text = "${placemarks[0].locality}, ${placemarks[0].street}";
      setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                /////////////////////////////////////////////////////////////
                SizedBox(height: 10.0,),
                Text("INFORMACION DE LA MASCOTA",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
              
                SizedBox(height: 10.0,),
                //////////////////////////////////////////////////
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownButton<String>(
                    focusColor:Colors.white,
                    value: _chosenValue,
                    //elevation: 5,
                    style: TextStyle(color: Colors.white),
                    iconEnabledColor:Colors.black,
                    items: <String>[
                      'Mi mascota se perdio',
                      'Encontre una mascota',
                      'Quiero dar en adopcion',
                      ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value,style:TextStyle(color:Colors.black),),
                      );
                    }).toList(),
                    hint:Text(
                      "Por que quieres publicar en nuestra aplicacion",
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                    onChanged: (String value) {
                      setState(() {
                        _chosenValue = value;
                        switch (value) {
                          case "Mi mascota se perdio":
                              estadoMascota = "PERDIDO";
                            break;
                          case "Encontre una mascota":
                              estadoMascota = "ENCONTRADO";
                            break;
                          case "Quiero dar en adopcion":
                              estadoMascota = "ADOPCION";
                            break;
                          default:
                            estadoMascota = "";
                        }
                        print(estadoMascota);
                      });
                    },
                  ),
                ),
                //////////////////////////////////////////////////
                SizedBox(height: 10.0,),
                Text("Que raza es la mascota?",style: styleText,),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        child: Column(
                          children: [
                            Image.asset(cat?"images/catc.png":"images/catb.png",fit: BoxFit.contain,width: 50,height: 50,),
                            Text("Gato")
                          ],
                        ),
                        onTap: (){
                          cat = true;
                          dog = false;
                          other = false;
                         setState(() {});
                        },
                      ),
                      GestureDetector(
                        child: Column(
                          children: [
                            Image.asset(dog?"images/dogc.png":"images/dogb.png",fit: BoxFit.contain,width: 50,height: 50,),
                            Text("Perro")
                          ],
                        ),
                        onTap: (){
                          cat = false;
                          dog = true;
                          other = false;
                         setState(() {});
                        },
                      ),
                      GestureDetector(
                        child: Column(
                          children: [
                            Image.asset(other?"images/otherc.png":"images/otherb.png",fit: BoxFit.contain,width: 50,height: 50,),
                            Text("Otro")
                          ],
                        ),
                        onTap: (){
                          cat = false;
                          dog = false;
                          other = true;
                         setState(() {});
                        },
                      ),
                    ],
                  ),
                ),
                /////////////////////////////////////////////////////////
                SizedBox(height: 10.0,),
                if(estadoMascota!="")FlatButton(
                  onPressed: () {
                  DatePicker.showDateTimePicker(context,
                      showTitleActions: true,
                      // minTime: DateTime(2018, 3, 5),
                      // maxTime: DateTime(2019, 6, 7), 
                  onChanged: (date) {
                    print('change $date');
                  }, onConfirm: (date) {
                    // print('confirm ${date.month.}');
                    setState(() {});
                    fechaEstado = "${date.day.toString().padLeft(2,"0")}/${date.month.toString().padLeft(2,"0")}/${date.year.toString()}" ;
                    horaEstado = "${date.hour.toString().padLeft(2,"0")}:${date.minute.toString().padLeft(2,"0")}" ;
                  }, currentTime: DateTime.now(), locale: LocaleType.es);
                  },
                  child: Column(
                    children: [
                      Text(
                          'Que fecha ${estadoMascota=="PERDIDO"?"se perdio":estadoMascota=="ENCONTRADO"?"fue encontrado":"nacio"}',
                          style: TextStyle(color: Colors.blue,fontSize: 16),
                      ),
                      Text(
                          "$fechaEstado  -  $horaEstado",
                          style: TextStyle(color: Colors.grey,fontSize: 25,)
                      ),
                    ],
                  )
                ),
                /////////////////////////////////////////////////////////
                SizedBox(height: 10.0,),
                Row(
                  children: [
                    FlatButton(
                      onPressed: getImage, 
                      child: Column(
                        children: [
                          Text("Suba una foto de la mascota",style: styleText,),
                            imageUrl==null?
                              Image.asset("images/upload.png",width: 150,height: 150,):
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: FadeInImage(
                                  placeholder: AssetImage("images/upload.png"), 
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                  width: 200,
                                  height: 200,
                                ),
                              ),
                        ],
                      )
                    ),
                    Column(
                      children: [
                          Text("Sexo",style: styleText,),
                          FlatButton(
                            onPressed: (){
                              macho = true;
                              hembra = false;
                              setState(() { });
                            }, 
                            child: Column(
                              children: [
                                Image.asset(!macho?"images/machob.png":"images/machoc.png",width: macho? 60:40,fit: BoxFit.cover,),
                                Text("MACHO")
                              ],
                            )
                          ),

                          FlatButton(
                            onPressed: (){
                              macho = false;
                              hembra = true;
                              setState(() { });
                            }, 
                            child: Column(
                              children: [
                                Image.asset(!hembra?"images/hembrab.png":"images/hembrac.png",width: hembra?60:40,fit: BoxFit.cover,),
                                Text("HEMBRA")
                              ],
                            )
                          ),
                      ],
                    )

                  ],
                ),
                /////////////////////////////////////////////////////////
                SizedBox(height: 10.0,),
                Text("Donde se perdio?",style: styleText,),
                Container(
                  width: double.infinity,
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      GoogleMap(
                        mapType: MapType.normal,
                        initialCameraPosition: positionMap,
                        rotateGesturesEnabled: false,
                        onCameraIdle: (){
                          print("hhhhhhhhh $positionMap");
                          _obtenerDireccion(positionMap.target.latitude,positionMap.target.longitude);
                        },
                        onCameraMove: (value){
                          // print("###### $value");
                          positionMap = value;
                        },
                        onCameraMoveStarted: (){
                          // print("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
                        },
                        onMapCreated: (GoogleMapController controller) {
                          _controller.complete(controller);
                        },
                        // markers: _markers,
                        // initialCameraPosition: kGooglePlex,
                        // onMapCreated: (GoogleMapController controller) {
                        //   _controller.complete(controller);
                        //   mapController = controller;

                        // },
                         gestureRecognizers: Set()
                        ..add(Factory<PanGestureRecognizer>(() => PanGestureRecognizer()))
                        ..add(Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),)
                        ..add(Factory<HorizontalDragGestureRecognizer>( () => HorizontalDragGestureRecognizer()),)
                        ..add(Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),),
                      ),
                      Image.asset("images/marker.png",width: 30,)
                    ],
                  ),
                ),
                /////////////////////////////////////////////////////////////
                SizedBox(height: 10.0,),
                Text("Detalle la direccion",style: styleText,),
                _labelInput(title: "Direccion", control: controllerDirecction),

                /////////////////////////////////////////////////////////////
                SizedBox(height: 10.0,),
                Text("Descripcion de la mascota",style: styleText,),
                _labelInput(title: "Descripcion", control: controllerDescription,helptext:"Ej. Se llama Abel vestia chompa azul, mide xxx...",descrip: true),

                /////////////////////////////////////////////////////////////
                SizedBox(height: 10.0,),
                Text("INFORMACION DE LA PERSONA",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                
                /////////////////////////////////////////////////////////////
                SizedBox(height: 10.0,),
                Text("Nombre del ${estadoMascota=="ENCONTRADO"?"rescatador":"propietario"}",style: styleText,),
                _labelInput(title: "Nombre", control: controllerNameProp,),

                /////////////////////////////////////////////////////////////
                SizedBox(height: 10.0,),
                Text("Numero del ${estadoMascota=="ENCONTRADO"?"rescatador":"propietario"}",style: styleText,),
                _labelInput(title: "Numero", control: controllerNumberProp,isNumber: true,helptext: "Se recomienda que tenga whatsapp"),

                /////////////////////////////////////////////////////////////
                SizedBox(height: 10.0,),
                AddMascota(
                  userId : "${this.widget.currentUserId}",
                  estadoMascota : "${estadoMascota=="PERDIDO"?"PERDIDO":estadoMascota=="ENCONTRADO"?"ENCONTRADO":estadoMascota=="ADOPCION"?"EN ADOPCION":""}",
                  tipoMascota : "${(cat)?"GATO":(dog)?"PERRO":(other)?"OTRO":""}",
                  fecha : "$fechaEstado",
                  hora : "$horaEstado",
                  urlImageMascota : "$imageUrl",
                  sexoMascota : "${macho?"MACHO":(hembra)?"HEMBRA":""}",
                  coordenadasMascota : "${positionMap.target.latitude},${positionMap.target.longitude}",
                  ciudadMascota : "$ciudad",
                  direccionMascota : "$direccion",
                  descripcionMascota : "${controllerDescription.text}",
                  namePropietario : "${controllerNameProp.text}",
                  numberPropietario : "${controllerNumberProp.text}",
                ),
                SizedBox(height: 20.0,),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool isLoading;
  File imageFile;
  String imageUrl;

  Future getImage() async {

    ImagePicker imagePicker = ImagePicker();
    PickedFile pickedFile;

    pickedFile = await imagePicker.getImage(source: ImageSource.gallery);
    imageFile = File(pickedFile.path);

    if (imageFile != null) {
      setState(() {
        isLoading = true;
      });
      uploadFile();
    }
  }

  Future uploadFile() async {
      Fluttertoast.showToast(msg: 'Porfavor espere mientras cargan los datos de la imagen',backgroundColor: Colors.green);

    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putFile(imageFile);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    await storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
      imageUrl = downloadUrl;
      setState(() {
        isLoading = false;
        // onSendMessage(imageUrl, 1);

      });
    }, onError: (err) {
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: 'This file is not an image');
    });
  }

  //////////////////////////////////////////
  CameraPosition positionMap = new CameraPosition(
    target: LatLng(-16.482557865279468, -68.1214064732194),
    zoom: 16
  );

  Completer<GoogleMapController> _controller = Completer();
  Future<void> _moveTo(CameraPosition position) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(position));
  }

  ////////////////////////////////////////////
  _labelInput({@required String title,@required TextEditingController control, bool descrip = false, String helptext, bool isNumber = false}){
    return Container(
      //margin: EdgeInsets.symmetric(horizontal: 30,vertical: 10),
      margin: EdgeInsets.only(right: 20,bottom: 10,top: 10),
      width: double.infinity,
      child: Row(
        children: [
          // Text("$title:"),
          Expanded(
            child: Container(
              padding: EdgeInsets.only(left: 20),
              child: TextField(
                minLines: (descrip)? 3:1,
                maxLines: (descrip)?10:1,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: title,
                  helperText: helptext,

                ),
                keyboardType: isNumber? TextInputType.phone:TextInputType.text,
                controller: control,
                onChanged: (value) {
                  setState(() {
                    
                  });
                },
                // onChanged: (n) {
                //   print("completo########");
                //   if(!ordenData.flagEdit){ordenData.flagEdit = true;}
                // },
              ),
            ),
          )
        ],
      ),
    );
  }

}

class AddMascota extends StatelessWidget {
  // final String fullName;
  // final String company;
  // final int age;

  final String userId;

  final String estadoMascota;
  final String tipoMascota;
  final String fecha;
  final String hora;
  final String urlImageMascota;
  final String sexoMascota;
  final String coordenadasMascota;
  final String ciudadMascota;
  final String direccionMascota;
  final String descripcionMascota;
  final String namePropietario;
  final String numberPropietario;

  const AddMascota({
    this.userId, 
    this.estadoMascota, 
    this.tipoMascota, 
    this.fecha, 
    this.hora, 
    this.urlImageMascota, 
    this.sexoMascota, 
    this.coordenadasMascota, 
    this.ciudadMascota, 
    this.direccionMascota, 
    this.descripcionMascota, 
    this.namePropietario, 
    this.numberPropietario
  });

  // AddMascota(this.fullName, this.company, this.age);

  @override
  Widget build(BuildContext context) {
    // Create a CollectionReference called users that references the firestore collection
    CollectionReference mascota = FirebaseFirestore.instance.collection('Mascota');

    Future<void> addMascota() {
      // Call the user's CollectionReference to add a new user
      return mascota
          .add({
            'userId':userId,
            'estadoMascota':estadoMascota,
            'tipoMascota':tipoMascota,
            'fecha':fecha,
            'hora':hora,
            'urlImageMascota':urlImageMascota,
            'sexoMascota':sexoMascota,
            'coordenadasMascota':coordenadasMascota,
            'ciudadMascota':ciudadMascota,
            'direccionMascota':direccionMascota,
            'descripcionMascota':descripcionMascota,
            'namePropietario':namePropietario,
            'numberPropietario':numberPropietario,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'stateComplete':false
          })
          .then((value) { 

          Fluttertoast.showToast(
          msg: 'SE PUBLICO CORRECTAMENTE',
          backgroundColor: Colors.black,
          textColor: Colors.white);
          print("Mascota Added ${value.id}");
          FirebaseFirestore.instance.collection('Mascota').doc(value.id)
            .update({'id': value.id})
            .then((value) => print("User Updated"))
            .catchError((error) => print("Failed to update user: $error"));
            Future.delayed(Duration(seconds: 2),(){
              context.findAncestorStateOfType<HomeScreenState>().restartApp();
            });
          })
          .catchError((error) => print("Failed to add mascota: $error"));
    }

    return CupertinoButton(
      onPressed: (){
        if(
          userId.length >0 &&
          estadoMascota.length >0 &&
          tipoMascota.length >0 &&
          fecha.length >0 &&
          hora.length >0 &&
          urlImageMascota.length >0 &&
          sexoMascota.length >0 &&
          coordenadasMascota.length >0 &&
          ciudadMascota.length >0 &&
          direccionMascota.length >0 &&
          descripcionMascota.length >0 &&
          namePropietario.length >0 &&
          numberPropietario.length >0 
        ){
          Fluttertoast.showToast(
          msg: 'ESPERE MIENTRAS SE PUBLICA',
          backgroundColor: Colors.green,
          textColor: Colors.white);
          addMascota();
        }
        else{
          print("""
          
          userId = $userId
          estadoMascota = $estadoMascota
          tipoMascota = $tipoMascota
          fecha = $fecha
          hora = $hora
          urlImageMascota = $urlImageMascota
          sexoMascota = $sexoMascota
          coordenadasMascota = $coordenadasMascota
          ciudadMascota = $ciudadMascota
          direccionMascota = $direccionMascota
          descripcionMascota = $descripcionMascota
          namePropietario = $namePropietario
          numberPropietario = $numberPropietario

          """);
          Fluttertoast.showToast(
          msg: 'POR FAVOR LLENE TODOS LOS CAMPOS',
          backgroundColor: Colors.red,
          textColor: Colors.white);
        }
      },
      color: Colors.green,
      child: Text(
        "Publicar",
      ),
    );
  }
}

class PageListMascotas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: StreamBuilder(
                stream:
                    FirebaseFirestore.instance.collection('Mascota').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                          ),
                          Text("Es posible que no tengas ninguna publicacion")
                        ],
                      ),
                    );
                  } else {
                    return ListView.builder(
                      padding: EdgeInsets.all(10.0),
                      itemBuilder: (context, index) =>
                          targetItem(context, snapshot.data.documents[index]),
                      itemCount: snapshot.data.documents.length,
                    );
                  }
                },
              ),
            
      // List
            // Container(
            //   child: StreamBuilder(
            //     stream:
            //         FirebaseFirestore.instance.collection('users').snapshots(),
            //     builder: (context, snapshot) {
            //       if (!snapshot.hasData) {
            //         return Center(
            //           child: CircularProgressIndicator(
            //             valueColor: AlwaysStoppedAnimation<Color>(themeColor),
            //           ),
            //         );
            //       } else {
            //         return ListView.builder(
            //           padding: EdgeInsets.all(10.0),
            //           itemBuilder: (context, index) =>
            //               buildItem(context, snapshot.data.documents[index]),
            //           itemCount: snapshot.data.documents.length,
            //         );
            //       }
            //     },
            //   ),
            // ),
    );
  }

  ///////////////
  ///
  
  Widget targetItem(BuildContext context, DocumentSnapshot document) {
    return Container(
      // padding: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15)
      ),
        child: Column(
          children: <Widget>[
            FlatButton(
              onPressed: () {
                
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FullPhoto(
                            url: document.data()['urlImageMascota'],
                            )));
              },
              child: Container(
                width: MediaQuery.of(context).size.width*0.85,
                height: MediaQuery.of(context).size.width*0.85,
                child: Stack(
                  children: [
                    Material(
                      child: document.data()['urlImageMascota'] != null
                          ? CachedNetworkImage(
                              placeholder: (context, url) => Container(
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.0,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(themeColor),
                                ),
                                width: MediaQuery.of(context).size.width*0.85,
                                height: MediaQuery.of(context).size.width*0.85,
                                padding: EdgeInsets.all(15.0),
                              ),
                              imageUrl: document.data()['urlImageMascota'],
                              width: MediaQuery.of(context).size.width*0.85,
                              height: MediaQuery.of(context).size.width*0.85,
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              Icons.account_circle,
                              size: MediaQuery.of(context).size.width*0.85,
                              color: greyColor,
                            ),
                      borderRadius: BorderRadius.all(Radius.circular(25.0)),
                      clipBehavior: Clip.hardEdge,
                    ),
                    Positioned(
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20,vertical: 10),
                        decoration: BoxDecoration(
                          color: document.data()['estadoMascota']=="PERDIDO"?Colors.purple:(document.data()['estadoMascota']=="ENCONTRADO")?Colors.green:(document.data()['estadoMascota']=="EN ADOPCION")?Colors.orange:Colors.green,
                          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15))
                        ),
                        child: Text("${document.data()['estadoMascota']=="PERDIDO"?"PERDIDO":(document.data()['estadoMascota']=="ENCONTRADO")?"ENCONTRADO":(document.data()['estadoMascota']=="EN ADOPCION")?"EN ADOPCION":"DESCONOCIDO"}",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Image.asset(
                        document.data()['tipoMascota']=="PERRO"?"images/dogc.png":document.data()['tipoMascota']=="GATO"?"images/catc.png":document.data()['tipoMascota']=="OTRO"?"images/otherc.png":"images/otherc.png",
                        height: 50,
                        width: 50,
                      )
                    )
                  ],
                ),
              ),
            ),
            SizedBox(height: 15,),
            Container(
              width: MediaQuery.of(context).size.width*0.8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[

                  RichText(
                    text: TextSpan(
                        text: '${document.data()['estadoMascota']=="PERDIDO"?"Me perdi el dia:":(document.data()['estadoMascota']=="ENCONTRADO")?"Me encontraron el dia:":(document.data()['estadoMascota']=="EN ADOPCION")?"Naci la fecha:":"Me perdi el dia:"}',
                        style: TextStyle(
                            color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                        children: <TextSpan>[
                          TextSpan(text: ' ${document.data()['fecha']}',
                              style: TextStyle(
                                  color: Colors.black, fontSize: 14,fontWeight: FontWeight.normal),
                          )
                        ]
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                        text: 'A horas:',
                        style: TextStyle(
                            color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                        children: <TextSpan>[
                          TextSpan(text: ' ${document.data()['hora']}',
                              style: TextStyle(
                                  color: Colors.black, fontSize: 14,fontWeight: FontWeight.normal),
                          )
                        ]
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                        text: 'En la zona:',
                        style: TextStyle(
                            color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                        children: <TextSpan>[
                          TextSpan(text: ' ${document.data()['ciudadMascota']}, ${document.data()['direccionMascota']}',
                              style: TextStyle(
                                  color: Colors.black, fontSize: 14,fontWeight: FontWeight.normal),
                          )
                        ]
                    ),
                  ),

                  RichText(
                    text: TextSpan(
                        text: 'Soy de sexo',
                        style: TextStyle(
                            color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                        children: <TextSpan>[
                          TextSpan(text: ' ${(document.data()['sexoMascota']=="HEMBRA")?"FEMENINO":"MASCULINO"}',
                              style: TextStyle(
                                  color: Colors.black, fontSize: 14,fontWeight: FontWeight.normal),
                          )
                        ]
                    ),
                  ),

                  RichText(
                    text: TextSpan(
                        text: 'Mi Descripcion:',
                        style: TextStyle(
                            color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                        children: <TextSpan>[
                          TextSpan(text: ' ${document.data()['descripcionMascota']}',
                              style: TextStyle(
                                  color: Colors.black, fontSize: 14,fontWeight: FontWeight.normal),
                          )
                        ]
                    ),
                  ),


                  RichText(
                    text: TextSpan(
                        text: 'Nombre de mi ${document.data()['estadoMascota']=="PERDIDO"?"Dueño es:":(document.data()['estadoMascota']=="ENCONTRADO")?"rescatador es:":(document.data()['estadoMascota']=="ADOPCION")?"adoptador es:":"dueño es:"}',
                        style: TextStyle(
                            color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                        children: <TextSpan>[
                          TextSpan(text: ' ${document.data()['namePropietario']}',
                              style: TextStyle(
                                  color: Colors.black, fontSize: 14,fontWeight: FontWeight.normal),
                          )
                        ]
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                        text: 'Lo puedes llamar al numero:',
                        style: TextStyle(
                            color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                        children: <TextSpan>[
                          TextSpan(text: ' ${document.data()['numberPropietario']}',
                              style: TextStyle(
                                  color: Colors.black, fontSize: 14,fontWeight: FontWeight.normal),
                          )
                        ]
                    ),
                  ),

                ],
              ),
              // margin: EdgeInsets.only(left: 20.0),
            ),
            ////////////////////////////////////
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15),bottomRight:  Radius.circular(15))
              ),
              margin: EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: (){
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Chat(
                                      peerId: document.data()['userId'],
                                      peerAvatar: document.data()['urlImageMascota'],
                                    )));
                      },
                      child: Container(
                        alignment: Alignment.centerLeft,
                        height: 50,
                        child: Text("Mandar un mensaje..."),
                        padding: EdgeInsets.only(left: 20),
                  ),
                    )),
                  InkWell(
                    child: Container(
                      height: 50,
                      padding: EdgeInsets.symmetric(horizontal: 20) ,
                      child: Icon(Icons.copy),
                    ),
                    onTap: ()async {
                      Fluttertoast.showToast(
                      msg: 'Texto copiado',
                      backgroundColor: Colors.black,
                      textColor: Colors.white);

                      String texto = """${document.data()['estadoMascota']=="PERDIDO"?"Me perdi el dia:":(document.data()['estadoMascota']=="ENCONTRADO")?"Me encontraron el dia:":(document.data()['estadoMascota']=="EN ADOPCION")?"Naci la fecha:":"Me perdi el dia:"} ${document.data()['fecha']}
                      A horas: ${document.data()['hora']}
                      En la zona: ${document.data()['ciudadMascota']}, ${document.data()['direccionMascota']}
                      Soy de sexo: ${(document.data()['sexoMascota']=="HEMBRA")?"FEMENINO":"MASCULINO"}
                      Mi Descripcion: ${document.data()['descripcionMascota']}
                      Nombre de mi ${document.data()['estadoMascota']=="PERDIDO"?"Dueño es:":(document.data()['estadoMascota']=="ENCONTRADO")?"rescatador es:":(document.data()['estadoMascota']=="ADOPCION")?"adoptador es:":"dueño es:"} ${document.data()['namePropietario']}
                      Lo puedes llamar al numero: ${document.data()['numberPropietario']}
                      """;
                      Clipboard.setData(new ClipboardData(text: texto));
                    },
                  ),
                  InkWell(
                    child: Container(
                      height: 50,
                      padding: EdgeInsets.symmetric(horizontal: 20) ,
                      child: Icon(Icons.share),
                    ),
                    onTap: ()async {
                      String texto = """${document.data()['estadoMascota']=="PERDIDO"?"Me perdi el dia:":(document.data()['estadoMascota']=="ENCONTRADO")?"Me encontraron el dia:":(document.data()['estadoMascota']=="EN ADOPCION")?"Naci la fecha:":"Me perdi el dia:"} ${document.data()['fecha']}
                      *A horas:* ${document.data()['hora']}
                      *En la zona:* ${document.data()['ciudadMascota']}, ${document.data()['direccionMascota']}
                      *Soy de sexo:* ${(document.data()['sexoMascota']=="HEMBRA")?"FEMENINO":"MASCULINO"}
                      *Mi Descripcion:* ${document.data()['descripcionMascota']}
                      *Nombre de mi ${document.data()['estadoMascota']=="PERDIDO"?"Dueño es:*":(document.data()['estadoMascota']=="ENCONTRADO")?"rescatador es:*":(document.data()['estadoMascota']=="ADOPCION")?"adoptador es:*":"dueño es:*"} ${document.data()['namePropietario']}
                      *Lo puedes llamar al numero:* ${document.data()['numberPropietario']}
                      """;
                      // var response = await get("https://ar.zoetis.com/_locale-assets/mcm-portal-assets/publishingimages/especie/caninos_perro_img.png");
                      // var documentDirectory = await getApplicationDocumentsDirectory();

                      // File file = new File(
                      //   pat.join(documentDirectory.path, 'imagetest.png')
                      // );

                      // file.writeAsBytesSync(response.bodyBytes);
                      // print("DIRECCION PATH ### $file");
                      // // CachedNetworkImageProvider(url);
                      // // Share.share('check out my website https://example.com');
                      // Share.shareFiles(['$file'], text: 'Great picture');
                      var request = await HttpClient().getUrl(Uri.parse(document.data()['urlImageMascota']));
                      var response = await request.close();
                      Uint8List bytes = await consolidateHttpClientResponseBytes(response);
                      await Share.file('ESYS AMLOG', 'amlog.jpg', bytes, 'image/jpg',text: texto);
                    },
                  ),
                ],
              ),
            )
          ],
        ),
        margin: EdgeInsets.only(bottom: 10.0, left: 5.0, right: 5.0),
      );
    
    // if (document.data()['id'] == currentUserId) {
    //   return Container();
    // } else {
    //   return 
    // }
  }
}

class PageMapa extends StatefulWidget {
  @override
  _PageMapaState createState() => _PageMapaState();
}

class _PageMapaState extends State<PageMapa> {
  CameraPosition positionMap = new CameraPosition(
    target: LatLng(-16.482557865249468, -68.1214064432194),
    zoom: 16
  );
  Position position;
  GoogleMapController mapController;
  Completer<GoogleMapController> _controller = Completer();
  Future<void> _moveTo(CameraPosition position) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(position));
  }
  List<Placemark> placemarks;

  @override
  void initState() { 
    super.initState();
    _cargarDatos();
  }
    BitmapDescriptor doggreen;
    BitmapDescriptor dogpurple;
    BitmapDescriptor dogorange;
    BitmapDescriptor catgreen;
    BitmapDescriptor catpurple;
    BitmapDescriptor catorange;
    BitmapDescriptor othergreen;
    BitmapDescriptor otherpurple;
    BitmapDescriptor otherorange;
  _cargarDatos()async{
    try {
      position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      positionMap = CameraPosition(
        target: LatLng(position.latitude, position.longitude),
        zoom: 16
      );
        _obtenerDireccion(position.latitude, position.longitude);
      // setState(() async{
      // });
      _moveTo(positionMap);
      print("-----inicio-----");
    } catch (e) {
    }

    // pinLocationIcon = await BitmapDescriptor.fromAssetImage(ImageConfiguration(devicePixelRatio: 2.5),'assets/destination_map_marker.png');
    doggreen      = await BitmapDescriptor.fromAssetImage(ImageConfiguration(devicePixelRatio: 2.5),'images/doggreen.png');
    dogpurple     = await BitmapDescriptor.fromAssetImage(ImageConfiguration(devicePixelRatio: 2.5),'images/dogpurple.png');
    dogorange     = await BitmapDescriptor.fromAssetImage(ImageConfiguration(devicePixelRatio: 2.5),'images/dogorange.png');
    catgreen      = await BitmapDescriptor.fromAssetImage(ImageConfiguration(devicePixelRatio: 2.5),'images/catgreen.png');
    catpurple     = await BitmapDescriptor.fromAssetImage(ImageConfiguration(devicePixelRatio: 2.5),'images/catpurple.png');
    catorange     = await BitmapDescriptor.fromAssetImage(ImageConfiguration(devicePixelRatio: 2.5),'images/catorange.png');
    othergreen    = await BitmapDescriptor.fromAssetImage(ImageConfiguration(devicePixelRatio: 2.5),'images/othergreen.png');
    otherpurple   = await BitmapDescriptor.fromAssetImage(ImageConfiguration(devicePixelRatio: 2.5),'images/otherpurple.png');
    otherorange   = await BitmapDescriptor.fromAssetImage(ImageConfiguration(devicePixelRatio: 2.5),'images/otherorange.png');
  }  
  // @override
  // void initStatew() async{
  //   // TODO: implement didChangeDependencies
  //   super.didChangeDependencies();
  // }

  _returnIcon(String tipo, String estado){
    if(tipo =="PERRO" && estado == "PERDIDO") return dogpurple;
    if(tipo =="PERRO" && estado == "ENCONTRADO") return doggreen;
    if(tipo =="PERRO" && estado == "EN ADOPCION") return dogorange;
    if(tipo =="GATO" && estado == "PERDIDO") return catpurple;
    if(tipo =="GATO" && estado == "ENCONTRADO") return catgreen;
    if(tipo =="GATO" && estado == "EN ADOPCION") return catorange;
    if(tipo =="OTRO" && estado == "PERDIDO") return otherpurple;
    if(tipo =="OTRO" && estado == "ENCONTRADO") return othergreen;
    if(tipo =="OTRO" && estado == "EN ADOPCION") return otherorange;
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      child: StreamBuilder(
        stream:
            FirebaseFirestore.instance.collection('Mascota').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(themeColor),
              ),
            );
          } else {
            List lista = snapshot.data.documents;
            List<MarcadorMascota> listaMascotas = [];
            lista.forEach((element) { 
              print("##-- ${element.data()["id"]}- ${element.data()["coordenadasMascota"]}- ${element.data()["estadoMascota"]}- ${element.data()["tipoMascota"]}");
              List coordenadas = element.data()["coordenadasMascota"].split(",")??["",""];
              listaMascotas.add(
                new MarcadorMascota(
                  estado: element.data()["estadoMascota"],
                  idMascota: element.data()["id"],
                  tipoMascota: element.data()["tipoMascota"],
                  ubicacion:LatLng(double.parse(coordenadas[0]??0), double.parse(coordenadas[1]??0))
                )
              );
              // MarcadorMascota(
              //   estado: element.data()["estadoMascota"], 
              //   ubicacion: LatLng(coordenadas[0], coordenadas[1]), 
              //   idMascota: element.
              // );

            });
            print(listaMascotas);
            listaMascotas.forEach((element) { 
              _markers.add(
                Marker(
                  markerId: MarkerId(element.idMascota),
                  position: element.ubicacion,
                  icon: _returnIcon(element.tipoMascota,element.estado),
                  
                )
            );
            });
            return Container(
              width: double.infinity,
              height: double.infinity,
              child: Stack(
                children: [
                  GoogleMap(
                            mapType: MapType.normal,
                            initialCameraPosition: positionMap,
                            rotateGesturesEnabled: false,
                            onMapCreated: (GoogleMapController controller) {
                              _controller.complete(controller);
                            },
                            markers: _markers,
                            // initialCameraPosition: kGooglePlex,
                            // onMapCreated: (GoogleMapController controller) {
                            //   _controller.complete(controller);
                            //   mapController = controller;

                            // },
                            //  gestureRecognizers: Set()
                            // ..add(Factory<PanGestureRecognizer>(() => PanGestureRecognizer()))
                            // ..add(Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),)
                            // ..add(Factory<HorizontalDragGestureRecognizer>( () => HorizontalDragGestureRecognizer()),)
                            // ..add(Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),),
                          ),
                          Container(
                            width: double.infinity,
                            // height: 100,
                            padding: EdgeInsets.symmetric(horizontal: 20,vertical: 5),
                            // color: Colors.blue,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.purple,
                                      borderRadius: BorderRadius.circular(100)
                                    ),
                                    child: Text("PERDIDOS",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 12),textAlign: TextAlign.center),
                                  ),
                                  flex: 1,
                                ),
                                Expanded(
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(100)
                                    ),
                                    child: Text("ENCONTRADOS",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 12),textAlign: TextAlign.center),
                                  ),
                                  flex: 1,
                                ),
                                Expanded(
                                  child: Container(
                                    // alignment: Alignment.ce,
                                    padding: EdgeInsets.symmetric(vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.orange,
                                      borderRadius: BorderRadius.circular(100)
                                    ),
                                    child: Text("EN ADOPCION",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,fontSize: 12),textAlign: TextAlign.center,),
                                  ),
                                  flex: 1,
                                ),
                              ],
                            ),
                          )
                ],
              ),
            );
            // return ListView.builder(
            //   padding: EdgeInsets.all(10.0),
            //   itemBuilder: (context, index) =>
            //       buildItem(context, snapshot.data.documents[index]),
            //   itemCount: snapshot.data.documents.length,
            // );
          }
        },
      ),
    );
  }
  Set<Marker> _markers = {};
  _obtenerDireccion(double lat, double long)async{
    placemarks = await placemarkFromCoordinates(lat,long);
      // print(" placemarks[0].administrativeArea == ${placemarks[0].administrativeArea}");
      // print(" placemarks[0].country == ${placemarks[0].country}");
      // print(" placemarks[0].isoCountryCode == ${placemarks[0].isoCountryCode}");
      // print(" placemarks[0].locality == ${placemarks[0].locality}");
      // print(" placemarks[0].name == ${placemarks[0].name}");
      // print(" placemarks[0].postalCode == ${placemarks[0].postalCode}");
      // print(" placemarks[0].street == ${placemarks[0].street}");
      // print(" placemarks[0].subAdministrativeArea == ${placemarks[0].subAdministrativeArea}");
      // print(" placemarks[0].subLocality == ${placemarks[0].subLocality}");
      // print(" placemarks[0].subThoroughfare == ${placemarks[0].subThoroughfare}");
      // print(" placemarks[0].thoroughfare == ${placemarks[0].thoroughfare}");
      // ciudad = placemarks[0].locality;
      // direccion = placemarks[0].street;
      // controllerDirecction.text = "${placemarks[0].locality}, ${placemarks[0].street}";
      setState(() {});
  }
}

class MarcadorMascota{
  final String estado;
  final LatLng ubicacion;
  final String idMascota;
  final String tipoMascota;
  MarcadorMascota({@required this.estado,@required  this.ubicacion,@required  this.idMascota, @required this.tipoMascota});
}
/////////////////////////

class PageListMisMascotas extends StatelessWidget {
  final String currentUserId;

  const PageListMisMascotas({Key key, this.currentUserId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: StreamBuilder(
                stream:
                    FirebaseFirestore.instance.collection('Mascota').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(themeColor),
                          ),
                          Text("Es posible que no tengas ninguna publicacion")
                        ],
                      ),
                    );
                  } else {
                    print("### ${snapshot.data.documents.length}");
                    return ListView.builder(
                      padding: EdgeInsets.all(10.0),
                      itemBuilder: (context, index) =>
                          targetItem(context, snapshot.data.documents[index]),
                      itemCount: snapshot.data.documents.length,
                    );
                  }
                },
              ),
            
      // List
            // Container(
            //   child: StreamBuilder(
            //     stream:
            //         FirebaseFirestore.instance.collection('users').snapshots(),
            //     builder: (context, snapshot) {
            //       if (!snapshot.hasData) {
            //         return Center(
            //           child: CircularProgressIndicator(
            //             valueColor: AlwaysStoppedAnimation<Color>(themeColor),
            //           ),
            //         );
            //       } else {
            //         return ListView.builder(
            //           padding: EdgeInsets.all(10.0),
            //           itemBuilder: (context, index) =>
            //               buildItem(context, snapshot.data.documents[index]),
            //           itemCount: snapshot.data.documents.length,
            //         );
            //       }
            //     },
            //   ),
            // ),
    );
  }

  ///////////////
  ///
  
  Widget targetItem(BuildContext context, DocumentSnapshot document) {
    if(document.data()['userId'] == this.currentUserId){
      return Container(
      // padding: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15)
      ),
        child: Column(
          children: <Widget>[
            FlatButton(
              onPressed: () {
                
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => FullPhoto(
                            url: document.data()['urlImageMascota'],
                            )));
              },
              child: Container(
                width: MediaQuery.of(context).size.width*0.85,
                height: MediaQuery.of(context).size.width*0.85,
                child: Stack(
                  children: [
                    Material(
                      child: document.data()['urlImageMascota'] != null
                          ? CachedNetworkImage(
                              placeholder: (context, url) => Container(
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.0,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(themeColor),
                                ),
                                width: MediaQuery.of(context).size.width*0.85,
                                height: MediaQuery.of(context).size.width*0.85,
                                padding: EdgeInsets.all(15.0),
                              ),
                              imageUrl: document.data()['urlImageMascota'],
                              width: MediaQuery.of(context).size.width*0.85,
                              height: MediaQuery.of(context).size.width*0.85,
                              fit: BoxFit.cover,
                            )
                          : Icon(
                              Icons.account_circle,
                              size: MediaQuery.of(context).size.width*0.85,
                              color: greyColor,
                            ),
                      borderRadius: BorderRadius.all(Radius.circular(25.0)),
                      clipBehavior: Clip.hardEdge,
                    ),
                    Positioned(
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 20,vertical: 10),
                        decoration: BoxDecoration(
                          color: document.data()['estadoMascota']=="PERDIDO"?Colors.purple:(document.data()['estadoMascota']=="ENCONTRADO")?Colors.green:(document.data()['estadoMascota']=="EN ADOPCION")?Colors.orange:Colors.green,
                          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15))
                        ),
                        child: Text("${document.data()['estadoMascota']=="PERDIDO"?"PERDIDO":(document.data()['estadoMascota']=="ENCONTRADO")?"ENCONTRADO":(document.data()['estadoMascota']=="EN ADOPCION")?"EN ADOPCION":"DESCONOCIDO"}",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Image.asset(
                        document.data()['tipoMascota']=="PERRO"?"images/dogc.png":document.data()['tipoMascota']=="GATO"?"images/catc.png":document.data()['tipoMascota']=="OTRO"?"images/otherc.png":"images/otherc.png",
                        height: 50,
                        width: 50,
                      )
                    )
                  ],
                ),
              ),
            ),
            SizedBox(height: 15,),
            Container(
              width: MediaQuery.of(context).size.width*0.8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[

                  RichText(
                    text: TextSpan(
                        text: '${document.data()['estadoMascota']=="PERDIDO"?"Me perdi el dia:":(document.data()['estadoMascota']=="ENCONTRADO")?"Me encontraron el dia:":(document.data()['estadoMascota']=="EN ADOPCION")?"Naci la fecha:":"Me perdi el dia:"}',
                        style: TextStyle(
                            color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                        children: <TextSpan>[
                          TextSpan(text: ' ${document.data()['fecha']}',
                              style: TextStyle(
                                  color: Colors.black, fontSize: 14,fontWeight: FontWeight.normal),
                          )
                        ]
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                        text: 'A horas:',
                        style: TextStyle(
                            color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                        children: <TextSpan>[
                          TextSpan(text: ' ${document.data()['hora']}',
                              style: TextStyle(
                                  color: Colors.black, fontSize: 14,fontWeight: FontWeight.normal),
                          )
                        ]
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                        text: 'En la zona:',
                        style: TextStyle(
                            color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                        children: <TextSpan>[
                          TextSpan(text: ' ${document.data()['ciudadMascota']}, ${document.data()['direccionMascota']}',
                              style: TextStyle(
                                  color: Colors.black, fontSize: 14,fontWeight: FontWeight.normal),
                          )
                        ]
                    ),
                  ),

                  RichText(
                    text: TextSpan(
                        text: 'Soy de sexo',
                        style: TextStyle(
                            color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                        children: <TextSpan>[
                          TextSpan(text: ' ${(document.data()['sexoMascota']=="HEMBRA")?"FEMENINO":"MASCULINO"}',
                              style: TextStyle(
                                  color: Colors.black, fontSize: 14,fontWeight: FontWeight.normal),
                          )
                        ]
                    ),
                  ),

                  RichText(
                    text: TextSpan(
                        text: 'Mi Descripcion:',
                        style: TextStyle(
                            color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                        children: <TextSpan>[
                          TextSpan(text: ' ${document.data()['descripcionMascota']}',
                              style: TextStyle(
                                  color: Colors.black, fontSize: 14,fontWeight: FontWeight.normal),
                          )
                        ]
                    ),
                  ),


                  RichText(
                    text: TextSpan(
                        text: 'Nombre de mi ${document.data()['estadoMascota']=="PERDIDO"?"Dueño es:":(document.data()['estadoMascota']=="ENCONTRADO")?"rescatador es:":(document.data()['estadoMascota']=="ADOPCION")?"adoptador es:":"dueño es:"}',
                        style: TextStyle(
                            color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                        children: <TextSpan>[
                          TextSpan(text: ' ${document.data()['namePropietario']}',
                              style: TextStyle(
                                  color: Colors.black, fontSize: 14,fontWeight: FontWeight.normal),
                          )
                        ]
                    ),
                  ),
                  RichText(
                    text: TextSpan(
                        text: 'Lo puedes llamar al numero:',
                        style: TextStyle(
                            color: Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
                        children: <TextSpan>[
                          TextSpan(text: ' ${document.data()['numberPropietario']}',
                              style: TextStyle(
                                  color: Colors.black, fontSize: 14,fontWeight: FontWeight.normal),
                          )
                        ]
                    ),
                  ),

                ],
              ),
              // margin: EdgeInsets.only(left: 20.0),
            ),
            ////////////////////////////////////
            Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15),bottomRight:  Radius.circular(15))
              ),
              margin: EdgeInsets.only(top: 20),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: (){
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Chat(
                                      peerId: document.data()['userId'],
                                      peerAvatar: document.data()['urlImageMascota'],
                                    )));
                      },
                      child: Container(
                        alignment: Alignment.centerLeft,
                        height: 50,
                        child: Text("Mandar un mensaje..."),
                        padding: EdgeInsets.only(left: 20),
                  ),
                    )),
                  InkWell(
                    child: Container(
                      height: 50,
                      padding: EdgeInsets.symmetric(horizontal: 20) ,
                      child: Icon(Icons.copy),
                    ),
                    onTap: ()async {
                      Fluttertoast.showToast(
                      msg: 'Texto copiado',
                      backgroundColor: Colors.black,
                      textColor: Colors.white);

                      String texto = """${document.data()['estadoMascota']=="PERDIDO"?"Me perdi el dia:":(document.data()['estadoMascota']=="ENCONTRADO")?"Me encontraron el dia:":(document.data()['estadoMascota']=="EN ADOPCION")?"Naci la fecha:":"Me perdi el dia:"} ${document.data()['fecha']}
                      A horas: ${document.data()['hora']}
                      En la zona: ${document.data()['ciudadMascota']}, ${document.data()['direccionMascota']}
                      Soy de sexo: ${(document.data()['sexoMascota']=="HEMBRA")?"FEMENINO":"MASCULINO"}
                      Mi Descripcion: ${document.data()['descripcionMascota']}
                      Nombre de mi ${document.data()['estadoMascota']=="PERDIDO"?"Dueño es:":(document.data()['estadoMascota']=="ENCONTRADO")?"rescatador es:":(document.data()['estadoMascota']=="ADOPCION")?"adoptador es:":"dueño es:"} ${document.data()['namePropietario']}
                      Lo puedes llamar al numero: ${document.data()['numberPropietario']}
                      """;
                      Clipboard.setData(new ClipboardData(text: texto));
                    },
                  ),
                  InkWell(
                    child: Container(
                      height: 50,
                      padding: EdgeInsets.symmetric(horizontal: 20) ,
                      child: Icon(Icons.share),
                    ),
                    onTap: ()async {
                      String texto = """${document.data()['estadoMascota']=="PERDIDO"?"Me perdi el dia:":(document.data()['estadoMascota']=="ENCONTRADO")?"Me encontraron el dia:":(document.data()['estadoMascota']=="EN ADOPCION")?"Naci la fecha:":"Me perdi el dia:"} ${document.data()['fecha']}
                      *A horas:* ${document.data()['hora']}
                      *En la zona:* ${document.data()['ciudadMascota']}, ${document.data()['direccionMascota']}
                      *Soy de sexo:* ${(document.data()['sexoMascota']=="HEMBRA")?"FEMENINO":"MASCULINO"}
                      *Mi Descripcion:* ${document.data()['descripcionMascota']}
                      *Nombre de mi ${document.data()['estadoMascota']=="PERDIDO"?"Dueño es:*":(document.data()['estadoMascota']=="ENCONTRADO")?"rescatador es:*":(document.data()['estadoMascota']=="ADOPCION")?"adoptador es:*":"dueño es:*"} ${document.data()['namePropietario']}
                      *Lo puedes llamar al numero:* ${document.data()['numberPropietario']}
                      """;
                      // var response = await get("https://ar.zoetis.com/_locale-assets/mcm-portal-assets/publishingimages/especie/caninos_perro_img.png");
                      // var documentDirectory = await getApplicationDocumentsDirectory();

                      // File file = new File(
                      //   pat.join(documentDirectory.path, 'imagetest.png')
                      // );

                      // file.writeAsBytesSync(response.bodyBytes);
                      // print("DIRECCION PATH ### $file");
                      // // CachedNetworkImageProvider(url);
                      // // Share.share('check out my website https://example.com');
                      // Share.shareFiles(['$file'], text: 'Great picture');
                      var request = await HttpClient().getUrl(Uri.parse(document.data()['urlImageMascota']));
                      var response = await request.close();
                      Uint8List bytes = await consolidateHttpClientResponseBytes(response);
                      await Share.file('ESYS AMLOG', 'amlog.jpg', bytes, 'image/jpg',text: texto);
                    },
                  ),
                ],
              ),
            ),
            // Container(
            //   height: 50,
            //   // color: Colors.blue,
            //   child: Row(
            //     children: [
            //       Expanded(
            //         child: InkWell(
            //           onTap: (){
            //             Navigator.push(
            //                 context,
            //                 MaterialPageRoute(
            //                     builder: (context) => EditarMascota(
            //                         ciudadMascota: document.data()['ciudadMascota'],
            //                         coordenadasMascota: document.data()['coordenadasMascota'],
            //                         currentUserId: this.currentUserId,
            //                         descripcionMascota: document.data()['descripcionMascota'],
            //                         direccionMascota: document.data()['direccionMascota'],
            //                         estadoMascota: document.data()['estadoMascota'],
            //                         fecha: document.data()['fecha'],
            //                         hora: document.data()['hora'],
            //                         namePropietario: document.data()['namePropietario'],
            //                         numberPropietario: document.data()['numberPropietario'],
            //                         sexoMascota: document.data()['sexoMascota'],
            //                         tipoMascota: document.data()['tipoMascota'],
            //                         urlImageMascota: document.data()['urlImageMascota'],
            //                         idMascota:document.data()['if']
            //                         )));
            //           },
            //           child: Container(
            //             alignment: Alignment.centerLeft,
            //             height: 50,
            //             color: Colors.green,
            //             child: Text("EDITAR",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,)),
            //             padding: EdgeInsets.only(left: 20),
            //       ),
            //         )),Expanded(
            //         child: InkWell(
            //           onTap: (){
            //             Navigator.push(
            //                 context,
            //                 MaterialPageRoute(
            //                     builder: (context) => Chat(
            //                           peerId: document.data()['userId'],
            //                           peerAvatar: document.data()['urlImageMascota'],
            //                         )));
            //           },
            //           child: Container(
            //             alignment: Alignment.centerLeft,
            //             height: 50,
            //             color: Colors.red,
            //             child: Text("ELIMINAR",style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold,)),
            //             padding: EdgeInsets.only(left: 20),
            //       ),
            //         )),
            //     ],
            //   ),
            // )
          ],
        ),
        margin: EdgeInsets.only(bottom: 10.0, left: 5.0, right: 5.0),
      );
    
    }else{
      return Container();
    }
    // if (document.data()['id'] == currentUserId) {
    //   return Container();
    // } else {
    //   return 
    // }
  }
}


////////////////////////
///

// class EditarMascota extends StatefulWidget {
//   final String currentUserId;
//   final String estadoMascota;
//   final String tipoMascota;
//   final String fecha;
//   final String hora;
//   final String urlImageMascota;
//   final String sexoMascota;
//   final String coordenadasMascota;
//   final String ciudadMascota;
//   final String direccionMascota;
//   final String descripcionMascota;
//   final String namePropietario;
//   final String numberPropietario;
//   final String idMascota;

//   const EditarMascota({@required this.currentUserId,
//   @required this.estadoMascota,
//   @required  this.tipoMascota,
//   @required   this.fecha,
//   @required    this.hora,
//   @required     this.urlImageMascota,
//   @required      this.sexoMascota,
//   @required       this.coordenadasMascota,
//   @required        this.ciudadMascota,
//   @required         this.direccionMascota,
//   @required          this.descripcionMascota,
//   @required           this.namePropietario,
//   @required            this.numberPropietario, this.idMascota}) ;
//   @override
//   _EditarMascotaState createState() => _EditarMascotaState();
// }

// class _EditarMascotaState extends State<EditarMascota> {

//   TextStyle styleText = TextStyle(fontSize: 16,fontWeight: FontWeight.w500);

//   String _chosenValue;

//   bool cat = false;
//   bool dog = false;
//   bool other = false;

//   bool macho = false;
//   bool hembra = false;

//   String estadoMascota = "";
//   String fechaEstado = "--/--/----";

//   String horaEstado = "00:00";

//   TextEditingController controllerDirecction;
//   TextEditingController controllerDescription;
//   TextEditingController controllerNameProp;
//   TextEditingController controllerNumberProp;

//   @override
//   void initState() {
//     super.initState();
//     controllerDirecction = new TextEditingController();
//     controllerDescription = new TextEditingController();
//     controllerNameProp = new TextEditingController();
//     controllerNumberProp = new TextEditingController();
//     readLocalization();
//     cargarDatos();
//   }
//   cargarDatos(){
//     controllerDirecction.text = "${this.widget.ciudadMascota}, ${this.widget.direccionMascota}";
//     controllerDescription.text = this.widget.descripcionMascota;
//     controllerNameProp.text = this.widget.namePropietario;
//     controllerNumberProp.text = this.widget.numberPropietario;
//   }

  
//   Position position;
//   GoogleMapController mapController;
//   List<Placemark> placemarks;
//   void readLocalization() async{
//     try {
//       position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
//       positionMap = CameraPosition(
//         target: LatLng(position.latitude, position.longitude),
//         zoom: 16
//       );
//         _obtenerDireccion(position.latitude, position.longitude);
//       // setState(() async{
//       // });
//       _moveTo(positionMap);
//     } catch (e) {
//     }
//   }
//   String ciudad = "";
//   String direccion = "";
//   _obtenerDireccion(double lat, double long)async{
//     placemarks = await placemarkFromCoordinates(lat,long);
//       // print(" placemarks[0].administrativeArea == ${placemarks[0].administrativeArea}");
//       // print(" placemarks[0].country == ${placemarks[0].country}");
//       // print(" placemarks[0].isoCountryCode == ${placemarks[0].isoCountryCode}");
//       // print(" placemarks[0].locality == ${placemarks[0].locality}");
//       // print(" placemarks[0].name == ${placemarks[0].name}");
//       // print(" placemarks[0].postalCode == ${placemarks[0].postalCode}");
//       // print(" placemarks[0].street == ${placemarks[0].street}");
//       // print(" placemarks[0].subAdministrativeArea == ${placemarks[0].subAdministrativeArea}");
//       // print(" placemarks[0].subLocality == ${placemarks[0].subLocality}");
//       // print(" placemarks[0].subThoroughfare == ${placemarks[0].subThoroughfare}");
//       // print(" placemarks[0].thoroughfare == ${placemarks[0].thoroughfare}");
//       ciudad = placemarks[0].locality;
//       direccion = placemarks[0].street;
//       controllerDirecction.text = "${placemarks[0].locality}, ${placemarks[0].street}";
//       setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: GestureDetector(
//         onTap: () => FocusScope.of(context).unfocus(),
//         child: Center(
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 /////////////////////////////////////////////////////////////
//                 SizedBox(height: 10.0,),
//                 Text("INFORMACION DE LA MASCOTA",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
              
//                 SizedBox(height: 10.0,),
//                 //////////////////////////////////////////////////
//                 Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: DropdownButton<String>(
//                     focusColor:Colors.white,
//                     value: _chosenValue,
//                     //elevation: 5,
//                     style: TextStyle(color: Colors.white),
//                     iconEnabledColor:Colors.black,
//                     items: <String>[
//                       'Mi mascota se perdio',
//                       'Encontre una mascota',
//                       'Quiero dar en adopcion',
//                       ].map<DropdownMenuItem<String>>((String value) {
//                       return DropdownMenuItem<String>(
//                         value: value,
//                         child: Text(value,style:TextStyle(color:Colors.black),),
//                       );
//                     }).toList(),
//                     hint:Text(
//                       "Por que quieres publicar en nuestra aplicacion",
//                       style: TextStyle(
//                           color: Colors.black,
//                           fontSize: 14,
//                           fontWeight: FontWeight.w500),
//                     ),
//                     onChanged: (String value) {
//                       setState(() {
//                         _chosenValue = value;
//                         switch (value) {
//                           case "Mi mascota se perdio":
//                               estadoMascota = "PERDIDO";
//                             break;
//                           case "Encontre una mascota":
//                               estadoMascota = "ENCONTRADO";
//                             break;
//                           case "Quiero dar en adopcion":
//                               estadoMascota = "ADOPCION";
//                             break;
//                           default:
//                             estadoMascota = "";
//                         }
//                         print(estadoMascota);
//                       });
//                     },
//                   ),
//                 ),
//                 //////////////////////////////////////////////////
//                 SizedBox(height: 10.0,),
//                 Text("Que raza es la mascota?",style: styleText,),
//                 Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       GestureDetector(
//                         child: Column(
//                           children: [
//                             Image.asset(cat?"images/catc.png":"images/catb.png",fit: BoxFit.contain,width: 50,height: 50,),
//                             Text("Gato")
//                           ],
//                         ),
//                         onTap: (){
//                           cat = true;
//                           dog = false;
//                           other = false;
//                          setState(() {});
//                         },
//                       ),
//                       GestureDetector(
//                         child: Column(
//                           children: [
//                             Image.asset(dog?"images/dogc.png":"images/dogb.png",fit: BoxFit.contain,width: 50,height: 50,),
//                             Text("Perro")
//                           ],
//                         ),
//                         onTap: (){
//                           cat = false;
//                           dog = true;
//                           other = false;
//                          setState(() {});
//                         },
//                       ),
//                       GestureDetector(
//                         child: Column(
//                           children: [
//                             Image.asset(other?"images/otherc.png":"images/otherb.png",fit: BoxFit.contain,width: 50,height: 50,),
//                             Text("Otro")
//                           ],
//                         ),
//                         onTap: (){
//                           cat = false;
//                           dog = false;
//                           other = true;
//                          setState(() {});
//                         },
//                       ),
//                     ],
//                   ),
//                 ),
//                 /////////////////////////////////////////////////////////
//                 SizedBox(height: 10.0,),
//                 if(estadoMascota!="")FlatButton(
//                   onPressed: () {
//                   DatePicker.showDateTimePicker(context,
//                       showTitleActions: true,
//                       // minTime: DateTime(2018, 3, 5),
//                       // maxTime: DateTime(2019, 6, 7), 
//                   onChanged: (date) {
//                     print('change $date');
//                   }, onConfirm: (date) {
//                     // print('confirm ${date.month.}');
//                     setState(() {});
//                     fechaEstado = "${date.day.toString().padLeft(2,"0")}/${date.month.toString().padLeft(2,"0")}/${date.year.toString()}" ;
//                     horaEstado = "${date.hour.toString().padLeft(2,"0")}:${date.minute.toString().padLeft(2,"0")}" ;
//                   }, currentTime: DateTime.now(), locale: LocaleType.es);
//                   },
//                   child: Column(
//                     children: [
//                       Text(
//                           'Que fecha ${estadoMascota=="PERDIDO"?"se perdio":estadoMascota=="ENCONTRADO"?"fue encontrado":"nacio"}',
//                           style: TextStyle(color: Colors.blue,fontSize: 16),
//                       ),
//                       Text(
//                           "$fechaEstado  -  $horaEstado",
//                           style: TextStyle(color: Colors.grey,fontSize: 25,)
//                       ),
//                     ],
//                   )
//                 ),
//                 /////////////////////////////////////////////////////////
//                 SizedBox(height: 10.0,),
//                 Row(
//                   children: [
//                     FlatButton(
//                       onPressed: getImage, 
//                       child: Column(
//                         children: [
//                           Text("Suba una foto de la mascota",style: styleText,),
//                             imageUrl==null?
//                               Image.asset("images/upload.png",width: 150,height: 150,):
//                               ClipRRect(
//                                 borderRadius: BorderRadius.circular(20),
//                                 child: FadeInImage(
//                                   placeholder: AssetImage("images/upload.png"), 
//                                   image: NetworkImage(imageUrl),
//                                   fit: BoxFit.cover,
//                                   width: 200,
//                                   height: 200,
//                                 ),
//                               ),
//                         ],
//                       )
//                     ),
//                     Column(
//                       children: [
//                           Text("Sexo",style: styleText,),
//                           FlatButton(
//                             onPressed: (){
//                               macho = true;
//                               hembra = false;
//                               setState(() { });
//                             }, 
//                             child: Column(
//                               children: [
//                                 Image.asset(!macho?"images/machob.png":"images/machoc.png",width: macho? 60:40,fit: BoxFit.cover,),
//                                 Text("MACHO")
//                               ],
//                             )
//                           ),

//                           FlatButton(
//                             onPressed: (){
//                               macho = false;
//                               hembra = true;
//                               setState(() { });
//                             }, 
//                             child: Column(
//                               children: [
//                                 Image.asset(!hembra?"images/hembrab.png":"images/hembrac.png",width: hembra?60:40,fit: BoxFit.cover,),
//                                 Text("HEMBRA")
//                               ],
//                             )
//                           ),
//                       ],
//                     )

//                   ],
//                 ),
//                 /////////////////////////////////////////////////////////
//                 SizedBox(height: 10.0,),
//                 Text("Donde se perdio?",style: styleText,),
//                 Container(
//                   width: double.infinity,
//                   height: 200,
//                   child: Stack(
//                     alignment: Alignment.center,
//                     children: [
//                       GoogleMap(
//                         mapType: MapType.normal,
//                         initialCameraPosition: positionMap,
//                         rotateGesturesEnabled: false,
//                         onCameraIdle: (){
//                           print("hhhhhhhhh $positionMap");
//                           _obtenerDireccion(positionMap.target.latitude,positionMap.target.longitude);
//                         },
//                         onCameraMove: (value){
//                           // print("###### $value");
//                           positionMap = value;
//                         },
//                         onCameraMoveStarted: (){
//                           // print("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX");
//                         },
//                         onMapCreated: (GoogleMapController controller) {
//                           _controller.complete(controller);
//                         },
//                         // markers: _markers,
//                         // initialCameraPosition: kGooglePlex,
//                         // onMapCreated: (GoogleMapController controller) {
//                         //   _controller.complete(controller);
//                         //   mapController = controller;

//                         // },
//                          gestureRecognizers: Set()
//                         ..add(Factory<PanGestureRecognizer>(() => PanGestureRecognizer()))
//                         ..add(Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),)
//                         ..add(Factory<HorizontalDragGestureRecognizer>( () => HorizontalDragGestureRecognizer()),)
//                         ..add(Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),),
//                       ),
//                       Image.asset("images/marker.png",width: 30,)
//                     ],
//                   ),
//                 ),
//                 /////////////////////////////////////////////////////////////
//                 SizedBox(height: 10.0,),
//                 Text("Detalle la direccion",style: styleText,),
//                 _labelInput(title: "Direccion", control: controllerDirecction),

//                 /////////////////////////////////////////////////////////////
//                 SizedBox(height: 10.0,),
//                 Text("Descripcion de la mascota",style: styleText,),
//                 _labelInput(title: "Descripcion", control: controllerDescription,helptext:"Ej. Se llama Abel vestia chompa azul, mide xxx...",descrip: true),

//                 /////////////////////////////////////////////////////////////
//                 SizedBox(height: 10.0,),
//                 Text("INFORMACION DE LA PERSONA",style: TextStyle(fontSize: 20,fontWeight: FontWeight.bold),),
                
//                 /////////////////////////////////////////////////////////////
//                 SizedBox(height: 10.0,),
//                 Text("Nombre del ${estadoMascota=="ENCONTRADO"?"rescatador":"propietario"}",style: styleText,),
//                 _labelInput(title: "Nombre", control: controllerNameProp,),

//                 /////////////////////////////////////////////////////////////
//                 SizedBox(height: 10.0,),
//                 Text("Numero del ${estadoMascota=="ENCONTRADO"?"rescatador":"propietario"}",style: styleText,),
//                 _labelInput(title: "Numero", control: controllerNumberProp,isNumber: true,helptext: "Se recomienda que tenga whatsapp"),

//                 /////////////////////////////////////////////////////////////
//                 SizedBox(height: 10.0,),
//                 AddMascota(
//                   userId : "${this.widget.currentUserId}",
//                   estadoMascota : "${estadoMascota=="PERDIDO"?"PERDIDO":estadoMascota=="ENCONTRADO"?"ENCONTRADO":estadoMascota=="ADOPCION"?"EN ADOPCION":""}",
//                   tipoMascota : "${(cat)?"GATO":(dog)?"PERRO":(other)?"OTRO":""}",
//                   fecha : "$fechaEstado",
//                   hora : "$horaEstado",
//                   urlImageMascota : "$imageUrl",
//                   sexoMascota : "${macho?"MACHO":(hembra)?"HEMBRA":""}",
//                   coordenadasMascota : "${positionMap.target.latitude},${positionMap.target.longitude}",
//                   ciudadMascota : "$ciudad",
//                   direccionMascota : "$direccion",
//                   descripcionMascota : "${controllerDescription.text}",
//                   namePropietario : "${controllerNameProp.text}",
//                   numberPropietario : "${controllerNumberProp.text}",
//                 ),
//                 SizedBox(height: 20.0,),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   bool isLoading;
//   File imageFile;
//   String imageUrl;

//   Future getImage() async {

//     ImagePicker imagePicker = ImagePicker();
//     PickedFile pickedFile;

//     pickedFile = await imagePicker.getImage(source: ImageSource.gallery);
//     imageFile = File(pickedFile.path);

//     if (imageFile != null) {
//       setState(() {
//         isLoading = true;
//       });
//       uploadFile();
//     }
//   }

//   Future uploadFile() async {
//       Fluttertoast.showToast(msg: 'Porfavor espere mientras cargan los datos de la imagen',backgroundColor: Colors.green);

//     String fileName = DateTime.now().millisecondsSinceEpoch.toString();
//     StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
//     StorageUploadTask uploadTask = reference.putFile(imageFile);
//     StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
//     await storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
//       imageUrl = downloadUrl;
//       setState(() {
//         isLoading = false;
//         // onSendMessage(imageUrl, 1);

//       });
//     }, onError: (err) {
//       setState(() {
//         isLoading = false;
//       });
//       Fluttertoast.showToast(msg: 'This file is not an image');
//     });
//   }

//   //////////////////////////////////////////
//   CameraPosition positionMap = new CameraPosition(
//     target: LatLng(-16.482557865279468, -68.1214064732194),
//     zoom: 16
//   );

//   Completer<GoogleMapController> _controller = Completer();
//   Future<void> _moveTo(CameraPosition position) async {
//     final GoogleMapController controller = await _controller.future;
//     controller.animateCamera(CameraUpdate.newCameraPosition(position));
//   }

//   ////////////////////////////////////////////
//   _labelInput({@required String title,@required TextEditingController control, bool descrip = false, String helptext, bool isNumber = false}){
//     return Container(
//       //margin: EdgeInsets.symmetric(horizontal: 30,vertical: 10),
//       margin: EdgeInsets.only(right: 20,bottom: 10,top: 10),
//       width: double.infinity,
//       child: Row(
//         children: [
//           // Text("$title:"),
//           Expanded(
//             child: Container(
//               padding: EdgeInsets.only(left: 20),
//               child: TextField(
//                 minLines: (descrip)? 3:1,
//                 maxLines: (descrip)?10:1,
//                 decoration: InputDecoration(
//                   border: OutlineInputBorder(),
//                   labelText: title,
//                   helperText: helptext,

//                 ),
//                 keyboardType: isNumber? TextInputType.phone:TextInputType.text,
//                 controller: control,
//                 onChanged: (value) {
//                   setState(() {
                    
//                   });
//                 },
//                 // onChanged: (n) {
//                 //   print("completo########");
//                 //   if(!ordenData.flagEdit){ordenData.flagEdit = true;}
//                 // },
//               ),
//             ),
//           )
//         ],
//       ),
//     );
//   }

// }
