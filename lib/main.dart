import 'dart:convert'; //for json encode
import 'dart:io';
import 'package:_crudapp/firebase_options.dart';
import 'package:_crudapp/firebase_services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
//import 'package:http/http.dart' as http; //for http post
import 'package:googleapis_auth/auth_io.dart' as auth; //for Google API auth
import 'package:image_picker/image_picker.dart';

import 'about_page.dart';
import 'auth_proc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const AuthGate(),
      //home: const MyHomePage(title: 'Flutter Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  String _token = 'Fetching token...';
  String _message = 'Waiting for message';
  String _notificationTitle = '';
  String _notificationBody = '';
  String? selectedItem;
  String _selectedToken = '';
  List<Map<String, dynamic>> items = [];
  bool isLoading = true;
  bool _customTileExpanded = false;
  bool _customTileExpanded2 = false;
  bool _customTileExpanded3 = false;
  bool _customTileExpanded4 = false;
  int _notificationCount = 0;
  String _currentUser = '';
  String _textToedit = '';
  String _docId = '';
  List<File> _images = <File>[]; // List to store selected images.
  File? _imagePhoto = null;
  Uint8List? _imageBytes;
  int _imgcnt = 0;
  final ImagePicker picker = ImagePicker();
  late String? photoURL;
  late String? displayName;

  @override
  void initState() {
    super.initState();
    _getFirebaseMessagingToken();
    // Initialize Firebase Messaging
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    // Request permission for push notifications
    messaging.requestPermission();
    _configureFCMListeners();
    // Show the dialog after the first frame is rendered.
    //WidgetsBinding.instance.addPostFrameCallback((_) {
    //  showWelcomeBox();
    //});
    fetchData();
    final user = FirebaseAuth.instance.currentUser;
    photoURL = user?.photoURL;
    displayName = user?.displayName;
  }

  Future<void> _loadDocData() async {
    try {
      final documentData = await firestoreServices.fetchTokenDocument(_token);

      setState(() {
        _docId = documentData['docId']; // Set the document ID
        _currentUser =
            documentData['username'].toString(); // Set the specific field value
      });
    } catch (e) {
      print('_loadDocData Error: $e');
    }
  }

  void showWelcomeBox() {
    String uMode = '';
    showDialog(
      context: context,
      builder: (context) {
        if (_currentUser != '') {
          controller.text = _currentUser;
          uMode = 'Update';
        } else {
          uMode = 'Add';
        }
        return AlertDialog(
          title: Text(
            "Welcome user $_currentUser",
            style: GoogleFonts.alexandria(fontSize: 16),
          ),
          content: Column(
            children: <Widget>[
              TextField(
                decoration: const InputDecoration(hintText: 'Username here...'),
                style: GoogleFonts.alexandria(),
                controller: controller,
              ),
              const SizedBox(
                  height: 10), // Add space between text and TextField
              Text(
                _token,
                style: GoogleFonts.alexandria(),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (_docId == '') {
                  firestoreServices.addToken(controller.text, _token);
                } else {
                  firestoreServices.updateToken(
                      _docId, controller.text, _token);
                  _currentUser = _textToedit;
                  print(
                      'showUserCreateBox updateToken: current user is $_currentUser');
                }
                controller.clear();
                Navigator.pop(context);
              },
              child: Text(
                uMode,
                style: GoogleFonts.alexandria(),
              ),
            )
          ],
        );
      },
    );
  }

  // This method is called to get the Firebase token
  Future<void> _getFirebaseMessagingToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      setState(() {
        _token = token ?? 'Failed to get token';
      });
      print("FCM Token: $_token");
      String currentUser = await firestoreServices.queryUsername(_token);
      setState(() {
        _currentUser = currentUser;
      });
      print('Fetching token: Your username is $currentUser');
      _loadDocData();
      // You can send this token to your server for push notifications
    } catch (e) {
      //print("Error getting token: $e");
      setState(() {
        _token = 'Error fetching token: $e';
      });
    }
  }

  Future<void> _configureFCMListeners() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // Handle incoming data message when the app is in the foreground
      setState(() {
        _notificationTitle = message.notification?.title ?? 'No Title';
        _notificationBody = message.notification?.body ?? 'No Body';
        _message =
            'Data message received: ${message.data}\nMessage title: $_notificationTitle\nMessage title: $_notificationBody';
        _notificationCount++;
      });
      String currentUser = await firestoreServices.queryUsername(_token);
      setState(() {
        _currentUser = currentUser;
      });
      firestoreServices.addMessage(
          currentUser, _token, _notificationTitle, _notificationBody);
      print('Listening to Message: Your username is $currentUser');
      print(
          'Handling background message title: ${message.notification?.title}');
      print('Handling background message body: ${message.notification?.body}');
      print(
          "Data message received: ${message.data}\n Message title: $_notificationTitle\n Message title: $_notificationBody");
      // Extract data and perform custom actions
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      // Handle incoming data message when the app is in the background or terminated
      setState(() {
        _notificationTitle = message.notification?.title ?? 'No Title';
        _notificationBody = message.notification?.body ?? 'No Body';
        _message = 'Data message opened: ${message.data}';
        _notificationCount++;
      });
      String currentUser = await firestoreServices.queryUsername(_token);
      setState(() {
        _currentUser = currentUser;
      });
      firestoreServices.addMessage(
          currentUser, _token, _notificationTitle, _notificationBody);
      //print("Data message opened: ${message.data}");
      // Extract data and perform custom actions
    });
  }

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  TextEditingController controller = TextEditingController();
  FirestoreServices firestoreServices = FirestoreServices();

  void showUserCreateBox(String? textToedit, String? docId, Timestamp? time) {
    String uMode = '';
    showDialog(
      context: context,
      builder: (context) {
        if (textToedit != null) {
          print('textToedit is $textToedit');
          print('showUserCreateBox: current user is $_currentUser');
          controller.text = textToedit;
          uMode = 'Edit';
          _textToedit = textToedit;
        } else {
          uMode = 'Add';
        }

        return AlertDialog(
          title: Text(
            "$uMode user",
            style: GoogleFonts.alexandria(fontSize: 16),
          ),
          content: Column(
            children: <Widget>[
              TextField(
                decoration: const InputDecoration(hintText: 'Username here...'),
                style: GoogleFonts.alexandria(),
                controller: controller,
              ),
              const SizedBox(
                  height: 10), // Add space between text and TextField
              Text(
                _token,
                style: GoogleFonts.alexandria(),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (docId == null) {
                  firestoreServices.addToken(controller.text, _token);
                } else {
                  firestoreServices.updateToken(docId, controller.text, _token);
                  _currentUser = _textToedit;
                  print(
                      'showUserCreateBox updateToken: current user is $_currentUser');
                }
                controller.clear();
                Navigator.pop(context);
              },
              child: Text(
                uMode,
                style: GoogleFonts.alexandria(),
              ),
            )
          ],
        );
      },
    );
  }

  // Fetch data from Firestore using the FirebaseServices class
  Future<void> fetchData() async {
    //List<String>? fetchedItems = await firestoreServices.fetchItems();
    List<Map<String, dynamic>>? fetchedItems =
        await firestoreServices.fetchItems();
    setState(() {
      items = fetchedItems;
      //if (items.isNotEmpty) {
      //  selectedItem = items[0] as String?; // Set the first item as default selection
      //}
      isLoading = false; // Update loading state
    });
  }

  // Controllers for the text fields
  TextEditingController titleController = TextEditingController();
  TextEditingController bodyController = TextEditingController();

  //dropdown selected value is only changed when cover alertdialog with statefulbuilder
  void showMessageBox(String? textToedit, String? docId, Timestamp? time) {
    // Fetch the users data when the dialog is opened
    fetchData();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (context, setState) => AlertDialog(
                  title: Text(
                    "Select a user",
                    style: GoogleFonts.alexandria(fontSize: 16),
                  ),
                  content: Column(
                    //mainAxisSize: MainAxisSize.min, // Prevents the content from stretching too much
                    children: <Widget>[
                      isLoading
                          ? const CircularProgressIndicator() // Show loading while fetching data
                          : DropdownButton<String>(
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedItem =
                                      newValue; // Update the selected value
                                  var selectedUser = items.firstWhere((item) =>
                                      item['username'] ==
                                      newValue); // Fetch other fields when a user is selected
                                  _selectedToken = selectedUser['token'] ?? '';
                                });
                                print('newValue is $newValue');
                              },
                              value: selectedItem,
                              //items: items.map<DropdownMenuItem<String>>((String value) {
                              items:
                                  items.map<DropdownMenuItem<String>>((item) {
                                return DropdownMenuItem<String>(
                                  //value: value,
                                  //child: Text(value),
                                  value: item['username'],
                                  child: Text(item['username']),
                                );
                              }).toList(),
                            ),
                      const SizedBox(
                          height: 10), // Add space between text and TextField
                      Text(
                        _selectedToken,
                        style: GoogleFonts.alexandria(),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration:
                            const InputDecoration(hintText: 'Title here...'),
                        style: GoogleFonts.alexandria(),
                        controller: titleController,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        decoration:
                            const InputDecoration(hintText: 'Body here...'),
                        style: GoogleFonts.alexandria(),
                        controller: bodyController,
                      ),
                    ],
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        String title = titleController.text;
                        String body = bodyController.text;

                        if (title.isNotEmpty && body.isNotEmpty) {
                          sendNotification(title, body, _selectedToken);
                        } else {
                          // Show error if fields are empty
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Error"),
                                content:
                                    const Text("Please fill out both fields."),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text("OK"),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                        controller.clear();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Send Message',
                        style: GoogleFonts.alexandria(),
                      ),
                    )
                  ],
                ));
      },
    );
  }

  // Send notification function Firebase Cloud Messaging API HTTP V1
  void sendNotification(String title, String body, String token) async {
    final jsonCredentials =
        await rootBundle.loadString('data/flutapp-eafa6-3193408a53f1.json');
    final creds = auth.ServiceAccountCredentials.fromJson(jsonCredentials);
    final client = await auth.clientViaServiceAccount(
      creds,
      ['https://www.googleapis.com/auth/cloud-platform'],
    );

    final notificationData = {
      'message': {
        'token': token,
        'notification': {'title': title, 'body': body}
      },
    };

    // Firebase notification payload
    //Map<String, dynamic> notification = {
    //'to': '/topics/your_topic',  // Send to a topic or use a device token
    //'to': token,
    //'notification': {
    //  'title': title,
    //  'body': body,
    //},
    //'data': {
    //  'click_action': 'FLUTTER_NOTIFICATION_CLICK',
    //  'id': '1',
    //  'status': 'done',
    //},
    //};

    // Sending notification via HTTP POST request to Firebase Cloud Messaging API
    try {
      //final response = await http.post(
      //  //Uri.parse('https://fcm.googleapis.com/fcm/send'),
      //  Uri.parse('https://fcm.googleapis.com/v1/projects/flutapp-eafa6/messages:send'),
      //  headers: <String, String>{
      //    'Content-Type': 'application/json',
      //    //'Authorization': 'key=YOUR_SERVER_KEY',  // Replace with your Firebase server key
      //  },
      //  body: json.encode(notification),
      //);

      const String senderId = '620340816204';
      final response = await client.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/$senderId/messages:send'),
        headers: {
          'content-type': 'application/json',
        },
        body: jsonEncode(notificationData),
      );

      client.close();

      if (response.statusCode == 200) {
        print("Notification sent successfully");
      } else {
        print("Failed to send notification: ${response.statusCode}");
      }
    } catch (e) {
      print("Error sending notification: $e");
    }
  }

  Future<void> _pickImage() async {
    // Request permission before picking an image on Android
    //PermissionStatus status = await Permission.photos.request();

    //if (status.isGranted) {

    //final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      String originalFilePath = image.path;
      print('image path is $originalFilePath');
      //final String _path = image.path;
      //final String _normalizedPath = _path.replaceAllMapped(
      //  RegExp(r'\.(PNG|JPG|JPEG)$', caseSensitive: true),
      //  (match) => match.group(0)!.toLowerCase(),
      //);
      print('image is not null');
      Uint8List? imageByte = await image.readAsBytes();
      //print('image bytes is $imageByte');
      setState(() {
        _imageBytes = imageByte;
        _imgcnt = 1;
      });
    }

    //} else {
    // Handle permission denied
    //print("Permission denied to access photos.");
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Alert"),
          content: const Text("Triggered Image Upload."),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
    //}
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error signing out. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // TRY THIS: Try changing the color here to a specific color (to
        // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
        // change color while the other colors stay the same.
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: () {
                  // Handle notification icon press
                  print("Notification icon tapped");
                  setState(() {
                    _notificationCount--;
                  });
                },
              ),
              if (_notificationCount > 0)
                Positioned(
                  right: 5,
                  top: 3,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '$_notificationCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          if (photoURL != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: CircleAvatar(
                radius: 16,
                child: CachedNetworkImage(
                  imageUrl: photoURL!,
                  placeholder: (context, url) =>
                      const CircularProgressIndicator(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                  imageBuilder: (context, imageProvider) => CircleAvatar(
                    backgroundImage: imageProvider,
                    radius: 16,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Center(
                child: Text(
                  displayName ?? 'User',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthGate()),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error signing out: $e')),
                  );
                }
              },
            ),
          ]
        ],
      ),
      drawer: Drawer(
        width: 250,
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurple,
              ),
              child: Text(
                'Navigation Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: const Text('About'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        // Ensure the entire body is scrollable
        child: Column(
          children: <Widget>[
            Center(
              // Center is a layout widget. It takes a single child and positions it
              // in the middle of the parent.
              child: Column(
                // Column is also a layout widget. It takes a list of children and
                // arranges them vertically. By default, it sizes itself to fit its
                // children horizontally, and tries to be as tall as its parent.
                //
                // Column has various properties to control how it sizes itself and
                // how it positions its children. Here we use mainAxisAlignment to
                // center the children vertically; the main axis here is the vertical
                // axis because Columns are vertical (the cross axis would be
                // horizontal).
                //
                // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
                // action in the IDE, or press "p" in the console), to see the
                // wireframe for each widget.
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ExpansionTile(
                    title: const Text('User Profile'),
                    trailing: Icon(
                      _customTileExpanded
                          ? Icons.arrow_drop_down_circle
                          : Icons.arrow_drop_down,
                    ),
                    onExpansionChanged: (bool expanded) {
                      setState(() {
                        _customTileExpanded = expanded;
                      });
                    },
                    children: <Widget>[
                      const Text(
                        '1. You have pushed the button this many times:',
                      ),
                      Text(
                        '$_counter',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Text(
                        '2. Firebase Token:',
                      ),
                      Text(
                        _token,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const Text(
                        '3. Message Received:',
                      ),
                      Text(
                        _message,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20), // Adds space between the widgets
            ExpansionTile(
              title: const Text('User List'),
              trailing: Icon(
                _customTileExpanded2
                    ? Icons.arrow_drop_down_circle
                    : Icons.arrow_drop_down,
              ),
              onExpansionChanged: (bool expanded) {
                setState(() {
                  _customTileExpanded2 = expanded;
                });
              },
              children: <Widget>[
                StreamBuilder(
                  stream: FirestoreServices().showTokens(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      List noteList = snapshot.data!.docs;
                      return ListView.builder(
                        shrinkWrap:
                            true, // Make ListView take only the necessary space
                        itemCount: noteList.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot document = noteList[index];
                          String docId = document.id;
                          Map<String, dynamic> data =
                              document.data() as Map<String, dynamic>;
                          String username = data['username'];
                          Timestamp time = data['timestamp'];
                          return Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  tileColor: Colors.purple[100],
                                  title: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      username,
                                      style: GoogleFonts.alexandria(
                                          textStyle: TextStyle(
                                              color: Colors.purple[800],
                                              fontSize: 19)),
                                    ),
                                  ),
                                  trailing: Column(
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            color: Colors.purple[400],
                                            icon: const Icon(Icons.edit),
                                            onPressed: () {
                                              showUserCreateBox(
                                                  username, docId, time);
                                            },
                                          ),
                                          IconButton(
                                              color: Colors.purple[400],
                                              onPressed: () {
                                                firestoreServices
                                                    .deleteToken(docId);
                                              },
                                              icon: const Icon(Icons.delete))
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      time
                                          .toDate()
                                          .hour
                                          .toString()
                                          .padLeft(2, '0'),
                                      style: const TextStyle(
                                          color: Colors.purple,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const Text(":"),
                                    Text(
                                      time
                                          .toDate()
                                          .minute
                                          .toString()
                                          .padLeft(2, '0'),
                                      style: const TextStyle(
                                          color: Colors.purple,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          );
                        },
                      );
                    } else {
                      return const Center(
                        child: Text("Nothing to show...add tokens"),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20), // Adds space between the widgets
            ExpansionTile(
              title: const Text('User Message List'),
              trailing: Icon(
                _customTileExpanded3
                    ? Icons.arrow_drop_down_circle
                    : Icons.arrow_drop_down,
              ),
              onExpansionChanged: (bool expanded) {
                //String currentUser = await firestoreServices.queryUsername(_token);
                //print('My username is $currentUser');
                setState(() {
                  _customTileExpanded3 = expanded;
                  //_currentUser = currentUser;
                });
              },
              children: <Widget>[
                StreamBuilder(
                  stream: FirestoreServices().showMessages(_currentUser),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      print("Error: ${snapshot.error}");
                      //return Center(child: Text("Error: ${snapshot.error}"));
                    }

                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      List noteList = snapshot.data!.docs;
                      int msgctr = noteList.length;
                      print('message counters:  $msgctr');
                      return ListView.builder(
                        shrinkWrap:
                            true, // Make ListView take only the necessary space
                        itemCount: noteList.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot document = noteList[index];
                          //String docId = document.id;
                          Map<String, dynamic> data =
                              document.data() as Map<String, dynamic>;
                          String msgtitle = data['msgtitle'];
                          String msgbody = data['msgbody'];
                          String fullmsg = 'Title: $msgtitle\nBody: $msgbody';
                          Timestamp time = data['timestamp'];
                          return Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 14),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  tileColor: Colors.purple[100],
                                  title: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(
                                      fullmsg,
                                      style: GoogleFonts.alexandria(
                                          textStyle: TextStyle(
                                              color: Colors.purple[800],
                                              fontSize: 19)),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      time
                                          .toDate()
                                          .hour
                                          .toString()
                                          .padLeft(2, '0'),
                                      style: const TextStyle(
                                          color: Colors.purple,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const Text(":"),
                                    Text(
                                      time
                                          .toDate()
                                          .minute
                                          .toString()
                                          .padLeft(2, '0'),
                                      style: const TextStyle(
                                          color: Colors.purple,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              )
                            ],
                          );
                        },
                      );
                    } else {
                      return const Center(
                        child: Text("Nothing to show...add messages"),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20), // Adds space between the widgets
            ExpansionTile(
              title: const Text('User Image List'),
              trailing: Icon(
                _customTileExpanded4
                    ? Icons.arrow_drop_down_circle
                    : Icons.arrow_drop_down,
              ),
              onExpansionChanged: (bool expanded) {
                //String currentUser = await firestoreServices.queryUsername(_token);
                //print('My username is $currentUser');
                setState(() {
                  _customTileExpanded4 = expanded;
                  //_currentUser = currentUser;
                });
              },
              children: <Widget>[
                SizedBox(
                  height: 300,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3, // Number of columns in the grid.
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount:
                          _imgcnt + 1, // Add 1 for the "Add Image" button.
                      itemBuilder: (context, index) {
                        if (index == _imgcnt) {
                          // Add Image button.
                          //return GestureDetector(
                          /*
                          return InkWell(
                            onTap: _pickImage,
                            child: Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.add_a_photo, 
                              size: 40, color: Colors.black54),
                            ),
                          );
                          */
                          return ElevatedButton(
                            onPressed: _pickImage,
                            child: Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.add_a_photo,
                                  size: 40, color: Colors.black54),
                            ),
                          );
                        } else {
                          /*
                          return CircleAvatar(
                            radius: 0,
                            backgroundImage: MemoryImage(_imageBytes!),
                          );
                          */
                          // Display the selected image.
                          return Container(
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                //image: FileImage(_images[index] as File),
                                image: MemoryImage(_imageBytes!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.purple[200],
        //shadowColor: Colors.purple,
        //surfaceTintColor: Colors.purple,
        child: //Padding(
            //padding: EdgeInsets.all(16),
            //child: Row(
            Row(
          //mainAxisAlignment: MainAxisAlignment.spaceAround,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            //const Text("",
            //style: TextStyle(color: Colors.transparent), // Invisible text
            //),
            FloatingActionButton(
              //heroTag: null,
              heroTag: "fab1",
              onPressed: _incrementCounter,
              tooltip: 'Increment',
              child: const Icon(Icons.add),
            ),
            const SizedBox(width: 20), // Space between buttons
            FloatingActionButton(
              heroTag: "fab2",
              onPressed: () async {
                showUserCreateBox(null, null, null);
              },
              tooltip: 'Create User',
              child: const Icon(Icons.add),
            ),
            const SizedBox(width: 20), // Space between buttons
            FloatingActionButton(
              heroTag: "fab3",
              onPressed: () async {
                showMessageBox(null, null, null);
              },
              tooltip: 'Create Message',
              child: const Icon(Icons.add),
            ),
          ],
        ),
        //),
      ),
    );
  }
}
