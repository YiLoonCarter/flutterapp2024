import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreServices {
  // creating a collection named 'usertokens' under which
  // all the new tokens will be stored. 
  final CollectionReference? usertokens =
      FirebaseFirestore.instance.collection('usertokens');

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

  Future<void> updateToken(String docId, String newUsername, String newToken, Timestamp time) {
    return usertokens!.doc(docId).update({'username': newUsername,'token': newToken, 'timestamp': time});
  }

  // delete the data by accessing the particular
  // which we want to delete.

  Future<void> deleteToken(String docId) {
    return usertokens!.doc(docId).delete();
  }
}