import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Management',
      theme: ThemeData(
        primaryColor: const Color.fromARGB(255, 241, 243, 244),
        scaffoldBackgroundColor: Color.fromARGB(255, 21, 164, 13),
        colorScheme: ColorScheme.fromSwatch()
            .copyWith(secondary: Color.fromARGB(255, 178, 184, 205)),
      ),
      home: const Login(),
    );
  }
}

class Login extends StatelessWidget {
  const Login({Key? key});

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);

        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const Taskscreate()));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sign in with Google: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Login', textAlign: TextAlign.center), // Centered title
        centerTitle: true, // Center aligns the title
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => signInWithGoogle(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
          child: const Text('Sign in with Google account'),
        ),
      ),
    );
  }
}

class Taskscreate extends StatefulWidget {
  const Taskscreate({Key? key});

  @override
  _TaskscreateState createState() => _TaskscreateState();
}

class _TaskscreateState extends State<Taskscreate> {
  final TextEditingController _taskController = TextEditingController();

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const Login()));
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Login();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _taskController,
              decoration: InputDecoration(
                labelText: 'Enter task',
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _addTheTask(user!.uid, _taskController.text);
              _taskController.clear();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondary,
            ),
            child: const Text('Add Task'),
          ),
          Expanded(
            child: ListOfTasks(userId: user.uid),
          ),
        ],
      ),
    );
  }

  void _addTheTask(String userId, String taskName) {
    if (taskName.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .add({
        'name': taskName,
        'completed': false,
      });
    }
  }
}

class ListOfTasks extends StatelessWidget {
  final String userId;
  const ListOfTasks({required this.userId, Key? key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (!snapshot.hasData) {
          return const Center(child: Text('No tasks found.'));
        }

        final tasks = snapshot.data!.docs;
        return ListView.builder(
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            return TaskItem(task: tasks[index]);
          },
        );
      },
    );
  }
}

class TaskItem extends StatefulWidget {
  final QueryDocumentSnapshot task;
  const TaskItem({required this.task, Key? key});

  @override
  _TaskItemState createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> {
  void _showAddSubtaskDialog() {
    final TextEditingController subtaskController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Subtask'),
          content: TextField(
            controller: subtaskController,
            decoration: const InputDecoration(hintText: 'Enter subtask'),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                final String subtaskName = subtaskController.text;
                if (subtaskName.isNotEmpty) {
                  widget.task.reference.collection('subtasks').add({
                    'name': subtaskName,
                    'completed': false,
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _deleteTheTask() {
    widget.task.reference.delete();
  }

  @override
  Widget build(BuildContext context) {
    bool? completed = widget.task.get('completed');
    return ExpansionTile(
      title: Row(
        children: [
          Checkbox(
            value: completed,
            onChanged: (bool? value) {
              widget.task.reference.update({'completed': value});
            },
          ),
          Expanded(child: Text(widget.task.get('name'))),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: _deleteTheTask,
      ),
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: widget.task.reference.collection('subtasks').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            var subtasks = snapshot.data?.docs ?? [];
            return ListView(
              shrinkWrap: true,
              children: subtasks.map((DocumentSnapshot subtask) {
                bool? subCompleted = subtask.get('completed');
                return CheckboxListTile(
                  value: subCompleted,
                  onChanged: (bool? value) {
                    subtask.reference.update({'completed': value});
                  },
                  title: Text(subtask.get('name')),
                  secondary: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      subtask.reference.delete();
                    },
                  ),
                );
              }).toList(),
            );
          },
        ),
        ListTile(
          title: const Text('Add Subtask'),
          onTap: _showAddSubtaskDialog,
        ),
      ],
    );
  }
}
