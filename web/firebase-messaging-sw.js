// firebase-messaging-sw.js
importScripts('https://www.gstatic.com/firebasejs/10.10.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.10.0/firebase-messaging-compat.js');

// Initialize Firebase
const firebaseConfig = {
  apiKey: "AIzaSyD7BrK4eZEV0ld7zS_R0IGoL9BFig02oic",
  authDomain: "flutapp-eafa6.firebaseapp.com",
  projectId: "flutapp-eafa6",
  storageBucket: "flutapp-eafa6.firebasestorage.app",
  messagingSenderId: "620340816204",
  appId: "1:620340816204:web:7e5e76f70f0ca570a0c7e9"
};

firebase.initializeApp(firebaseConfig);

// Retrieve an instance of Firebase Messaging
const messaging = firebase.messaging();

// Handle background message
messaging.onBackgroundMessage(function(payload) {
  console.log('Received background message ', payload);
  // Customize notification here
  const notificationTitle = payload.notification.title || 'Background Message Title';
  const notificationOptions = {
    body: payload.notification.body || 'Background message body.',
    icon: '/firebase-logo.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});