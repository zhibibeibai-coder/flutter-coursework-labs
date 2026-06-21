import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'contact.dart';
import 'contact_database.dart';

void main() {
  runApp(const MiniContactsApp());
}

class MiniContactsApp extends StatelessWidget {
  const MiniContactsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MiniContacts',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const ContactsPage(),
    );
  }
}

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final ContactDatabase _database = ContactDatabase.instance;
  final ImagePicker _picker = ImagePicker();
  List<Contact> _contacts = <Contact>[];
  bool _loading = true;
  String? _message;

  @override
  void initState() {
    super.initState();
    _initContacts();
  }

  Future<void> _initContacts() async {
    await _database.seedFromAssetIfEmpty();
    await _loadContacts();
  }

  Future<void> _loadContacts() async {
    final List<Contact> contacts = await _database.readAll();
    setState(() {
      _contacts = contacts;
      _loading = false;
    });
  }

  Future<void> _addContact() async {
    final Contact? contact = await showDialog<Contact>(
      context: context,
      builder: (BuildContext context) => const ContactEditorDialog(),
    );
    if (contact == null) {
      return;
    }
    await _database.insert(contact);
    await _loadContacts();
  }

  Future<void> _deleteContact(Contact contact) async {
    if (contact.id == null) {
      return;
    }
    await _database.delete(contact.id!);
    await _loadContacts();
  }

  Future<void> _callContact(Contact contact) async {
    final Uri telUri = Uri(scheme: 'tel', path: contact.phone);
    final bool launched = await launchUrl(telUri);
    setState(() {
      _message = launched ? '正在拨打 ${contact.phone}' : '当前设备无法打开拨号组件';
    });
  }

  Future<void> _changeAvatar(Contact contact) async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (image == null) {
      setState(() {
        _message = '未拍摄新的头像';
      });
      return;
    }
    await _database.update(contact.copyWith(avatar: image.path));
    await _loadContacts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MiniContacts'),
        actions: <Widget>[
          IconButton(
            tooltip: '刷新',
            onPressed: _loadContacts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addContact,
        icon: const Icon(Icons.person_add_alt),
        label: const Text('添加'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: <Widget>[
                      if (_message != null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Text(_message!),
                        ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (BuildContext context, int index) {
                            final Contact contact = _contacts[index];
                            return ContactTile(
                              contact: contact,
                              onCall: () => _callContact(contact),
                              onDelete: () => _deleteContact(contact),
                              onChangeAvatar: () => _changeAvatar(contact),
                            );
                          },
                          separatorBuilder: (BuildContext context, int index) =>
                              const SizedBox(height: 10),
                          itemCount: _contacts.length,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class ContactTile extends StatelessWidget {
  const ContactTile({
    super.key,
    required this.contact,
    required this.onCall,
    required this.onDelete,
    required this.onChangeAvatar,
  });

  final Contact contact;
  final VoidCallback onCall;
  final VoidCallback onDelete;
  final VoidCallback onChangeAvatar;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: <Widget>[
            AvatarImage(path: contact.avatar),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    contact.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    contact.studentId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    contact.phone,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Wrap(
              spacing: 2,
              children: <Widget>[
                IconButton(
                  tooltip: '拨打电话',
                  onPressed: onCall,
                  icon: const Icon(Icons.call),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  tooltip: '更换头像',
                  onPressed: onChangeAvatar,
                  icon: const Icon(Icons.photo_camera),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  tooltip: '删除',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AvatarImage extends StatelessWidget {
  const AvatarImage({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final ImageProvider provider = path.startsWith('assets/')
        ? AssetImage(path)
        : FileImage(File(path));
    return CircleAvatar(radius: 28, backgroundImage: provider);
  }
}

class ContactEditorDialog extends StatefulWidget {
  const ContactEditorDialog({super.key});

  @override
  State<ContactEditorDialog> createState() => _ContactEditorDialogState();
}

class _ContactEditorDialogState extends State<ContactEditorDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void dispose() {
    _studentIdController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('添加联系人'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextFormField(
                controller: _studentIdController,
                decoration: const InputDecoration(labelText: '学号'),
                validator: _notEmpty,
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '姓名'),
                validator: _notEmpty,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: '电话'),
                keyboardType: TextInputType.phone,
                validator: _notEmpty,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        FilledButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }

  String? _notEmpty(String? value) {
    return value == null || value.trim().isEmpty ? '不能为空' : null;
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    Navigator.of(context).pop(
      Contact(
        studentId: _studentIdController.text.trim(),
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        avatar: 'assets/images/avatar_ye.png',
      ),
    );
  }
}
