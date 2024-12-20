import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreServices {
  // creating a collection named 'usertokens' under which
  // all the new tokens will be stored. 
  final CollectionReference? usertokens =
      FirebaseFirestore.instance.collection('usertokens');

  // creating a collection named 'usermsgs' under which
  // all the received messages will be stored. 
  final CollectionReference? usermsgs =
      FirebaseFirestore.instance.collection('usermsgs');

  // adding a new note logic within our 'usertokens' collection 
  // by creating 2 fields named
  // 'token' (token we enter) and 'timestamp'(time of entry)
  
  Future<void> addMessage(String username, String token, String msgtitle, String msgbody) {
    return usermsgs!.add(
      {'username': username,'token': token, 'msgtitle': msgtitle, 'msgbody': msgbody, 'timestamp': Timestamp.now()},
    );
  }

  // adding a new note logic within our 'usertokens' collection 
  // by creating 2 fields named
  // 'token' (token we enter) and 'timestamp'(time of entry)
  
  Future<void> addToken(String username, String token) {
    return usertokens!.add(
      {'username': username,'token': token, 'timestamp': Timestamp.now()},
    );
  }

  // reading data within the 'usertokens' collection
  // we have made earlier in the form of snapshots

  Stream<QuerySnapshot> showTokens() {
    final tokensStream =
        usertokens!.orderBy('timestamp', descending: true).snapshots();

    return tokensStream;
  }

  Stream<QuerySnapshot> showMessages(String username) {
    //print('query message with user name $username');
    //final msgsStream =
    return 
        usermsgs!
        .where('username', isEqualTo: username)
        .orderBy('timestamp', descending: true)
        .snapshots();

    //return msgsStream;
  }

  Future<String> queryUsername(String token) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('usertokens') // Replace 'usertokens' with your collection name
          .where('token', isEqualTo: token) // Replace 'token' and passed token
          .get();

      if (snapshot.docs.isNotEmpty) {
          //return snapshot.docs.first.data().toString();
          return snapshot.docs.first.get('username');
      } else {
          print("No records found");
      }
      return ""; // Return an empty value if there is an error
    } catch (e) {
        print("Error: $e");
        return ""; // Return an empty value if there is an error
    }
  }

  // Fetch the first document from a Firestore collection
  Future<Map<String, dynamic>> fetchTokenDocument(String token) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('usertokens')
        .where('token', isEqualTo: token) // Replace 'token' and passed token
        .get();

      if (querySnapshot.docs.isNotEmpty) {
        QueryDocumentSnapshot document = querySnapshot.docs.first;
        return {
          'docId': document.id,
          //'fields': document.data(),
          'username': document['username'],
        };
      } else {
        print('No documents found in the collection');
        return {};
      }
    } catch (e) {
      print('Error fetching document: $e');
      return {};
    }
  }

  // Fetch a list of items from Firestore collection
  //Future<List<String>?> fetchItems() async {
  Future<List<Map<String, dynamic>>> fetchItems() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('usertokens').get();
      List<Map<String, dynamic>> items = snapshot.docs.map((doc) {
        //return doc['username']; // Replace 'name' with the field you want to retrieve
        return doc.data() as Map<String, dynamic>; // Return the data from each document
      //}).cast<String>().toList();
      }).cast<Map<String, dynamic>>().toList();
      return items;
    } catch (e) {
      print('Error fetching items: $e');
      return []; // Return an empty list if there is an error
    }
  }

  // update the data by accessing the particular
  // docId of the note which we want to update.

  Future<void> updateToken(String docId, String newUsername, String newToken) {
    return usertokens!.doc(docId).update({'username': newUsername,'token': newToken, 'timestamp': Timestamp.now()});
  }

  // delete the data by accessing the particular
  // which we want to delete.

  Future<void> deleteToken(String docId) {
    return usertokens!.doc(docId).delete();
  }
}