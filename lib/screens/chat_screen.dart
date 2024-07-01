import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatmate/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'friend_profile.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:voice_message_package/voice_message_package.dart';
import 'settings.dart';

class ChatScreen extends StatefulWidget {
  static const String id = "chat_screen";

  final String recipientId;
  final String recipientName;
  final String profilePic;

  ChatScreen({
    required this.recipientId,
    required this.recipientName,
    required this.profilePic,
  });

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  FlutterSoundRecorder? _recorder;
  bool _isRecording = false;
  String? _recordingFilePath;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late User loggedIn;
  String msg = "";
  late String username;
  late String chattingWith;
  late int unreadMessages;
  final TextEditingController messageController = TextEditingController();
  bool isLoading = true;
  String reciverOnline = 'Offline';
  String type = 'text';
  String? imageFile = null;
  String? voiceNote = null;
  bool sending = false;

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    getRecipientStatus();
    messageSeen();
    _recorder = FlutterSoundRecorder();
    _recorder!.openRecorder();
  }

  Future<void> getRecipientStatus() async {
    var recipientDoc =
        await _firestore.collection('users').doc(widget.recipientId).get();
    var recipientData = recipientDoc.data() as Map<String, dynamic>;
    var currentChattingWith = recipientData['chattingWith'];
    setState(() {
      chattingWith = currentChattingWith;
      if (chattingWith == username) reciverOnline = 'online';
    });
    if (currentChattingWith != username) {
      var friendDoc = await _firestore
          .collection('users')
          .doc(widget.recipientId)
          .collection('friends')
          .doc(loggedIn.uid)
          .get();
      var friendData = friendDoc.data() as Map<String, dynamic>;
      var currentUnreadMessages = friendData['unreadMessages'];
      setState(() {
        unreadMessages = currentUnreadMessages;
      });
    } else {
      setState(() {
        unreadMessages = 0;
      });
    }
  }

  Future<String?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      return pickedFile.path;
    } else {
      return null;
    }
  }

  Future<void> uploadImage(String path) async {
    File file = File(path);
    String fileName =
        'images/${loggedIn.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
    await storageRef.putFile(file);
    String downloadUrl = await storageRef.getDownloadURL();

    chattingWith = await getChatWith();
    _firestore.collection('messages').add({
      'image': downloadUrl,
      'username': username,
      'time': FieldValue.serverTimestamp(),
      'participants': [loggedIn.uid, widget.recipientId],
      'seen': chattingWith == username ? 'true' : 'false',
      'type': 'image', // Add the type field
    });
    if (chattingWith != username || chattingWith.isEmpty) {
      await _firestore
          .collection('users')
          .doc(widget.recipientId)
          .collection('friends')
          .doc(loggedIn.uid)
          .update({'unreadMessages': FieldValue.increment(1)});
    } else {
      _firestore
          .collection('users')
          .doc(loggedIn.uid)
          .collection('friends')
          .doc(widget.recipientId)
          .update({'unreadMessages': 0});
    }
  }

  Future<void> startRecording() async {
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      status = await Permission.microphone.request();
      if (!status.isGranted) {
        // If the permission is not granted, show a message to the user.
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text('Microphone permission is required to record voice notes.'),
        ));
        return;
      }
    }

    Directory tempDir = await getTemporaryDirectory();
    String path = '${tempDir.path}/flutter_sound.aac';
    _recordingFilePath = path;

    await _recorder!.startRecorder(
      toFile: path,
      codec: Codec.aacADTS,
    );

    setState(() {
      _isRecording = true;
    });
  }

  Future<String?> stopRecording() async {
    String? path = await _recorder!.stopRecorder();
    setState(() {
      _isRecording = false;
    });
    if (path != null) {
      return path;
    }
    return null;
  }

  Future<void> uploadVoiceNote(String path) async {
    File file = File(path);
    String fileName =
        'voice_notes/${loggedIn.uid}_${DateTime.now().millisecondsSinceEpoch}.aac';
    Reference storageRef = FirebaseStorage.instance.ref().child(fileName);
    await storageRef.putFile(file);
    String downloadUrl = await storageRef.getDownloadURL();

    chattingWith = await getChatWith();
    _firestore.collection('messages').add({
      'voiceNote': downloadUrl,
      'username': username,
      'time': FieldValue.serverTimestamp(),
      'participants': [loggedIn.uid, widget.recipientId],
      'seen': chattingWith == username ? 'true' : 'false',
      'type': 'voiceNote', // Add the type field
    });
    if (chattingWith != username || chattingWith.isEmpty) {
      await _firestore
          .collection('users')
          .doc(widget.recipientId)
          .collection('friends')
          .doc(loggedIn.uid)
          .update({'unreadMessages': FieldValue.increment(1)});
    } else {
      _firestore
          .collection('users')
          .doc(loggedIn.uid)
          .collection('friends')
          .doc(widget.recipientId)
          .update({'unreadMessages': 0});
    }
  }

  Future<String> getChatWith() async {
    var recipientDoc =
        await _firestore.collection('users').doc(widget.recipientId).get();
    var recipientData = recipientDoc.data() as Map<String, dynamic>;
    var currentChattingWith = recipientData['chattingWith'];
    return currentChattingWith;
  }

  void getCurrentUser() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        loggedIn = user;

        var userData =
            await _firestore.collection('users').doc(loggedIn.uid).get();
        username = userData['username'];
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> messageSeen() async {
    var messagesSnapshot = await _firestore
        .collection('messages')
        .where('participants', arrayContains: widget.recipientId)
        .get();

    for (var d in messagesSnapshot.docs) {
      final data = d.data() as Map<String, dynamic>;
      if (data['seen'] == 'false' &&
          data['participants'][0] == widget.recipientId &&
          data['participants'][1] == loggedIn.uid) {
        await _firestore.collection('messages').doc(d.id).update({
          'seen': 'true',
        });
        print('done');
      }
    }
  }

  @override
  void dispose() async {
    super.dispose();
    await _firestore.collection('users').doc(loggedIn.uid).update({
      'chattingWith': '',
    });
    //_recorder!.closeAudioSession();
    if (_recorder != null) _recorder!.closeRecorder();
  }

  // void _clearChat(String userId, String friendId) async {
  //   bool confirm = await showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: Text('Confirm'),
  //         content: Text('Are you sure you want to clear the chat?'),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(false),
  //             child: Text('Cancel'),
  //           ),
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(true),
  //             child: Text('Yes'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  //   if (confirm) {
  //     setState(() {
  //       isLoading = true;
  //     });
  //     try {
  //       QuerySnapshot messagesSnapshot = await _firestore
  //           .collection('messages')
  //           .orderBy('time', descending: true)
  //           .get();
  //
  //       final chatMessages = messagesSnapshot.docs.where((doc) {
  //         final data = doc.data() as Map<String, dynamic>;
  //         final senderId = data['participants'][0];
  //         final recipientId = data['participants'][1];
  //         return (senderId == userId && recipientId == friendId) ||
  //             (senderId == friendId && recipientId == userId);
  //       }).toList();
  //
  //       for (DocumentSnapshot doc in chatMessages) {
  //         await doc.reference.delete();
  //       }
  //
  //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //         content: Text('Chat cleared'),
  //       ));
  //     } catch (e) {
  //       print('Error clearing chat: $e');
  //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //         content: Text('Failed to clear chat'),
  //       ));
  //     }
  //     setState(() {
  //       isLoading = false;
  //     });
  //   }
  // }

  Future<void> blockUser() async {
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block User'),
        content: Text('Are you sure you want to block this user?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Block'),
          ),
        ],
      ),
    );

    if (confirm) {
      try {
        await _firestore.collection('users').doc(loggedIn.uid).update({
          'blockedUsers': FieldValue.arrayUnion([widget.recipientId]),
        });

        Navigator.pop(context, confirm);

        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('User blocked'),
        ));
      } catch (e) {
        print('Error blocking user: $e');
      }
    }
  }

  Stream<DocumentSnapshot> getRecipientStatusStream(String recipientId) {
    return _firestore.collection('users').doc(recipientId).snapshots();
  }

  void info() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendProfileScreen(
          friendId: widget.recipientId,
          friendName: widget.recipientName,
          profilePic: widget.profilePic,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await messageSeen();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: SizedBox(),
          leadingWidth: 15,
          actions: <Widget>[
            PopupMenuButton<String>(
              onSelected: (String value) {
                if (value == 'info') {
                  info();
                  // } else if (value == 'clear_chat') {
                  //   _clearChat(loggedIn.uid, widget.recipientId);
                } else if (value == 'block_user') {
                  blockUser();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'info',
                  child: Text('Info'),
                ),
                // const PopupMenuItem<String>(
                //   value: 'clear_chat',
                //   child: Text('Clear Chat'),
                // ),
                const PopupMenuItem<String>(
                  value: 'block_user',
                  child: Text(
                    'Block User',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
          title: Row(
            children: [
              CircleAvatar(
                backgroundImage: widget.profilePic.isNotEmpty
                    ? NetworkImage(widget.profilePic)
                    : AssetImage('images/default_profile_pic.jpg')
                        as ImageProvider,
              ),
              StreamBuilder<DocumentSnapshot>(
                stream: getRecipientStatusStream(widget.recipientId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  }
                  if (snapshot.hasData) {
                    var recipientData =
                        snapshot.data!.data() as Map<String, dynamic>;
                    chattingWith = recipientData['chattingWith'];
                    reciverOnline =
                        chattingWith == username ? 'Online' : 'Offline';
                  }

                  return TextButton(
                    onPressed: () {
                      info();
                    },
                    child: Padding(
                      padding: EdgeInsets.only(left: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.recipientName}',
                            style: TextStyle(color: Colors.white, fontSize: 22),
                          ),
                          Text(
                            '${reciverOnline}',
                            style:
                                TextStyle(color: Colors.white70, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    MessagesStream(
                      firestore: _firestore,
                      senderId: loggedIn.uid,
                      recipientId: widget.recipientId,
                      chattingWith: chattingWith,
                    ),
                    Container(
                      decoration: kMessageContainerDecoration,
                      padding: EdgeInsets.fromLTRB(15, 10, 5, 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          if (type == 'voice' || type == 'text')
                            IconButton(
                              onPressed: () async {
                                setState(() {
                                  type = "voice";
                                });
                                _isRecording
                                    ? setState(() async {
                                        voiceNote = await stopRecording();
                                      })
                                    : startRecording();
                              },
                              icon: Icon(
                                _isRecording
                                    ? Icons.stop
                                    : Icons.mic_none_rounded,
                                size: 30,
                              ),
                              color: Colors.teal,
                            ),
                          Expanded(
                            child: Container(
                              constraints: BoxConstraints(
                                maxHeight: type == 'image' ? 400.0 : 200,
                              ),
                              child: type == 'image' && imageFile != null
                                  ? Image.file(
                                      File(imageFile!),
                                      fit: BoxFit.contain,
                                    )
                                  : type == 'voice' && voiceNote != null
                                      ? VoiceNotePlayer(
                                          voiceNoteUrl: voiceNote!)
                                      : TextField(
                                          controller: messageController,
                                          onChanged: (value) {
                                            msg = value;
                                          },
                                          decoration:
                                              kMessageTextFieldDecoration
                                                  .copyWith(
                                            hintText: _isRecording
                                                ? "Recording.."
                                                : "Type message here..",
                                            suffixIcon: IconButton(
                                              onPressed: () async {
                                                final imagePath =
                                                    await pickImage();
                                                if (imagePath != null) {
                                                  setState(() {
                                                    type = "image";
                                                    imageFile = imagePath;
                                                  });
                                                }
                                              },
                                              icon: Icon(
                                                Icons.camera_alt_outlined,
                                                size: 30,
                                              ),
                                              color: Colors.teal,
                                            ),
                                          ),
                                          maxLines: null,
                                          minLines: 1,
                                          keyboardType: TextInputType.multiline,
                                          textCapitalization:
                                              TextCapitalization.sentences,
                                          showCursor: true,
                                        ),
                            ),
                          ),
                          if ((type == 'image' && imageFile != null) ||
                              (type == 'voice' && voiceNote != null))
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  type = 'text';
                                  imageFile = null;
                                  voiceNote = null;
                                });
                              },
                              icon: Icon(
                                Icons.close,
                                size: 26,
                                color: Colors.red,
                              ),
                            ),
                          sending
                              ? CircularProgressIndicator(
                                  color: Colors.white70,
                                  strokeWidth: 2,
                                )
                              : IconButton(
                                  onPressed: () async {
                                    messageController.clear();
                                    if (type == 'text' && msg.isEmpty) return;
                                    chattingWith = await getChatWith();
                                    if (type == 'text') {
                                      _firestore.collection('messages').add({
                                        'text': msg,
                                        'username': username,
                                        'time': FieldValue.serverTimestamp(),
                                        'participants': [
                                          loggedIn.uid,
                                          widget.recipientId,
                                        ],
                                        'seen': chattingWith == username
                                            ? 'true'
                                            : 'false',
                                        'type': 'text',
                                      });
                                    } else if (type == 'image' &&
                                        imageFile != null) {
                                      setState(() {
                                        sending = true;
                                      });
                                      await uploadImage(imageFile!);
                                      setState(() {
                                        sending = false;
                                      });
                                    } else if (type == 'voice' &&
                                        voiceNote != null) {
                                      setState(() {
                                        sending = true;
                                      });
                                      await uploadVoiceNote(voiceNote!);
                                      setState(() {
                                        sending = false;
                                      });
                                    }
                                    setState(() {
                                      msg = "";
                                      type = "text";
                                    });
                                    if (chattingWith != username ||
                                        chattingWith.isEmpty) {
                                      await _firestore
                                          .collection('users')
                                          .doc(widget.recipientId)
                                          .collection('friends')
                                          .doc(loggedIn.uid)
                                          .update({
                                        'unreadMessages':
                                            FieldValue.increment(1),
                                      });
                                    } else {
                                      _firestore
                                          .collection('users')
                                          .doc(loggedIn.uid)
                                          .collection('friends')
                                          .doc(widget.recipientId)
                                          .update({
                                        'unreadMessages': 0,
                                      });
                                    }
                                  },
                                  icon: Icon(Icons.send, size: 35),
                                  color: Colors.teal,
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class MessagesStream extends StatelessWidget {
  final FirebaseFirestore firestore;
  final String senderId;
  final String recipientId;
  final String chattingWith;

  MessagesStream({
    required this.firestore,
    required this.senderId,
    required this.recipientId,
    required this.chattingWith,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('messages')
          .orderBy('time', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              backgroundColor: Colors.blue,
              color: Colors.white,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text('No messages found.'),
          );
        }

        final messages = snapshot.data!.docs.where((doc) {
          List<dynamic> participants = doc['participants'];
          return participants.contains(senderId) &&
              participants.contains(recipientId);
        }).toList();

        List<MessageBubble> messageBubbles = [];

        for (var message in messages) {
          final content;
          final messageType = message['type'];
          final messageSender = message['username'];
          final messageTime = message['time'] as Timestamp?;
          final messageId = message.id;
          if (messageType == 'text' && message['text'].isNotEmpty) {
            content = message['text'];
          } else if (messageType == 'image') {
            content = message['image'];
          } else if (messageType == 'voiceNote') {
            content = message['voiceNote'];
          } else
            continue;

          final currentUser = FirebaseAuth.instance.currentUser?.uid;
          final isSeen =
              chattingWith == messageSender ? true : message['seen'] == 'true';

          final messageBubble = MessageBubble(
            sender: messageSender,
            text: messageType == 'text' ? content : null,
            voiceNote: messageType == 'voiceNote' ? content : null,
            isMe: currentUser == message['participants'][0],
            time: messageTime != null
                ? (messageTime as Timestamp).toDate()
                : null,
            isSeen: message['seen'] == 'true',
            type: messageType,
            messageId: messageId,
            image: messageType == 'image' ? content : null,
            // Pass the type to the MessageBubble
          );

          messageBubbles.add(messageBubble);
        }

        return Expanded(
          child: ListView(
            reverse: true,
            padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 20.0),
            children: messageBubbles,
          ),
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  final String sender;
  final String? text;
  final bool isMe;
  final DateTime? time;
  final String messageId;
  final bool isSeen;
  final String? voiceNote;
  final String type;
  final String? image;

  MessageBubble({
    required this.sender,
    required this.text,
    required this.isMe,
    required this.time,
    required this.messageId,
    required this.isSeen,
    required this.voiceNote,
    required this.type,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            sender,
            style: TextStyle(
              fontSize: 13.0,
              color: Colors.white60,
            ),
          ),
          GestureDetector(
            onLongPressStart: (details) =>
                _showOptionsDialog(context, details.globalPosition),
            child: Container(
              margin: isMe
                  ? EdgeInsets.only(left: 70.0)
                  : EdgeInsets.only(right: 70.0),
              child: Material(
                borderRadius: isMe
                    ? BorderRadius.only(
                        topLeft: Radius.circular(15.0),
                        bottomLeft: Radius.circular(15.0),
                        bottomRight: Radius.circular(15.0),
                        topRight: Radius.circular(0.0),
                      )
                    : BorderRadius.only(
                        topRight: Radius.circular(15.0),
                        bottomLeft: Radius.circular(15.0),
                        bottomRight: Radius.circular(15.0),
                        topLeft: Radius.circular(0.0),
                      ),
                elevation: 5.0,
                color: isMe ? Colors.teal : Colors.black38,
                child: Padding(
                  padding: type == 'image'
                      ? EdgeInsets.all(5)
                      : EdgeInsets.symmetric(vertical: 7.0, horizontal: 10.0),
                  child: Column(
                    crossAxisAlignment: isMe
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      _buildContentWidget(context),
                      SizedBox(height: 2.0),
                      if (time != null)
                        Text(
                          '${time!.hour}:${time!.minute}',
                          style: TextStyle(
                            fontSize: 10.0,
                            color: Colors.white54,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (isMe && isSeen)
            Text(
              'Seen',
              style: TextStyle(
                fontSize: 10.0,
                color: Colors.blueAccent,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContentWidget(BuildContext context) {
    if (type == 'text' && text!.isNotEmpty) {
      return Text(
        text!,
        style: TextStyle(
          color: Colors.white,
          fontSize: 15.0,
        ),
      );
    } else if (type == 'image') {
      return GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FullScreenImage(imageUrl: image!),
            ),
          );
        },
        child: Container(
          constraints: BoxConstraints(
            maxHeight: 350, // Maximum height
          ),
          child: Image.network(
            image!,
            fit: BoxFit.contain,
          ),
        ),
      );
    } else if (type == 'voiceNote') {
      return VoiceNotePlayer(
        voiceNoteUrl: voiceNote!,
      );
    } else {
      return SizedBox();
    }
  }

  void _showOptionsDialog(BuildContext context, Offset position) async {
    final result = await showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx + 1, position.dy + 1),
      items: [
        PopupMenuItem(
          child: Row(
            children: [
              if (isMe && type == 'text')
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showEditDialog(context);
                  },
                ),
              if (isMe)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await FirebaseFirestore.instance
                        .collection('messages')
                        .doc(messageId)
                        .delete();
                  },
                ),
            ],
          ),
        ),
      ],
      elevation: 0.0,
      color: Colors.transparent,
    );
  }

  void _showEditDialog(BuildContext context) {
    final TextEditingController editController =
        TextEditingController(text: text);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Message'),
          content: TextField(
            controller: editController,
            decoration: InputDecoration(hintText: "Enter your message"),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('messages')
                    .doc(messageId)
                    .update({'text': editController.text});
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class VoiceNotePlayer extends StatefulWidget {
  final String voiceNoteUrl;

  VoiceNotePlayer({required this.voiceNoteUrl});

  @override
  _VoiceNotePlayerState createState() => _VoiceNotePlayerState();
}

class _VoiceNotePlayerState extends State<VoiceNotePlayer> {
  FlutterSoundPlayer? _player;
  bool isPlaying = false;
  bool first = true;
  bool _loading = true;
  String msg = 'Tap to play';

  @override
  void initState() {
    super.initState();
    _player = FlutterSoundPlayer();
    _player!.openPlayer().then((value) {
      setState(() {
        _loading = false;
      });
    });
  }

  @override
  void dispose() {
    _player!.closePlayer();
    _player = null;
    super.dispose();
  }

  void togglePlayPause() async {
    if (isPlaying) {
      await _player!.pausePlayer();
      setState(() {
        isPlaying = false;
        msg = 'Tap to Resume';
      });
    } else if (first) {
      await _player!.startPlayer(
          fromURI: widget.voiceNoteUrl,
          codec: Codec.aacADTS,
          whenFinished: () {
            setState(() {
              isPlaying = false;
              first = true;
              msg = 'Play Again';
            });
          });
      setState(() {
        first = false;
        isPlaying = true;
        msg = 'Playing..';
      });

      // _player!.getPlayerState().whenComplete((){
      //   setState(() {
      //     isPlaying = false;
      //     first = true;
      //     msg='Play Again';
      //   });
      // });
    } else {
      await _player!.resumePlayer();
      setState(() {
        isPlaying = true;
        msg = 'Playing..';
      });
    }
  }

  void restartPlayback() {
    setState(() {
      first = true;
      isPlaying = false;
      msg = 'Playing..';
      togglePlayPause();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? CircularProgressIndicator(
            color: Colors.white70,
          ) // Display loading indicator while player is opening
        : GestureDetector(
            onTap: togglePlayPause,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
              decoration: BoxDecoration(
                color: isPlaying ? Colors.white : Colors.grey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPlaying ? Icons.pause : Icons.play_arrow,
                    color: isPlaying ? Colors.teal : Colors.white,
                  ),
                  SizedBox(width: 8.0),
                  Text(
                    msg,
                    style: TextStyle(
                        color: isPlaying ? Colors.teal : Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 8.0),
                  if (isPlaying)
                    IconButton(
                        icon: Icon(
                          Icons.restart_alt_outlined,
                          color: isPlaying ? Colors.teal : Colors.white,
                        ),
                        onPressed: restartPlayback),
                ],
              ),
            ),
          );
  }
}
