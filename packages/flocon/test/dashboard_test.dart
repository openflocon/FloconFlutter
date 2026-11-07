import 'dart:async';
import 'dart:convert';

import 'package:flocon/flocon.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

class _Sender implements FloconMessageSender {
  final sent = <({String plugin, String method, Map<String, dynamic> body})>[];
  @override
  void send({
    required String plugin,
    required String method,
    required String body,
  }) => sent.add((
    plugin: plugin,
    method: method,
    body: jsonDecode(body) as Map<String, dynamic>,
  ));
}

FloconMessageFromServer _msg(String method, Object body) =>
    FloconMessageFromServer(
      plugin: 'dashboard',
      method: method,
      body: body is String ? body : jsonEncode(body),
    );

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late _Sender sender;
  late FloconDashboardPlugin plugin;

  setUp(() {
    sender = _Sender();
    plugin = FloconDashboardPlugin(sender: sender);
  });

  test('a static dashboard is sent once, in the desktop format', () async {
    plugin.dashboard('main', [
      FloconSection('Build', [
        const FloconText('status', 'ok', color: 0xFFFF0000),
        const FloconLabel('A label'),
        const FloconPlainText('commit', 'abc123'),
        const FloconJson('config', '{"a":1}'),
        const FloconMarkdown('Release', '# 1.0'),
        const FloconHtml('About', '<h1>App</h1>'),
        FloconButton('Log out', id: 'logout', onClick: () {}),
        FloconTextField(
          id: 'rename',
          label: 'Rename',
          value: 'Flo',
          placeholder: 'name',
        ),
        FloconCheckBox(id: 'premium', label: 'Premium', value: true),
      ]),
      FloconForm(
        'Create user',
        [FloconTextField(id: 'name', label: 'Name', value: '')],
        submitText: 'Create',
        onSubmitted: (_) {},
      ),
    ]);
    await settle();

    final message = sender.sent.single;
    expect((message.plugin, message.method), ('dashboard', 'update'));
    expect(message.body['dashboardId'], 'main');
    final containers = (message.body['containers'] as List)
        .cast<Map<String, dynamic>>();
    expect(containers[0]['name'], 'Build');
    expect(containers[0]['containerConfig'], {'containerType': 'SECTION'});
    expect(containers[0]['elements'], [
      {
        'text': {'label': 'status', 'value': 'ok', 'color': -65536},
      },
      {
        'label': {'label': 'A label'},
      },
      {
        'plainText': {'label': 'commit', 'value': 'abc123', 'type': 'text'},
      },
      {
        'plainText': {'label': 'config', 'value': '{"a":1}', 'type': 'json'},
      },
      {
        'markdown': {'label': 'Release', 'value': '# 1.0'},
      },
      {
        'html': {'label': 'About', 'value': '<h1>App</h1>'},
      },
      {
        'button': {'id': 'main_logout', 'text': 'Log out'},
      },
      {
        'textField': {
          'id': 'main_rename',
          'label': 'Rename',
          'placeHolder': 'name',
          'value': 'Flo',
        },
      },
      {
        'checkBox': {'id': 'main_premium', 'label': 'Premium', 'value': true},
      },
    ]);
    expect(containers[1]['containerConfig'], {
      'containerType': 'FORM',
      'formId': 'main_form_Create user',
      'submitText': 'Create',
    });
  });

  test('actions of the desktop run the callbacks of the app', () async {
    final calls = <String>[];
    plugin.dashboard('main', [
      FloconSection('S', [
        FloconButton('Go', id: 'go', onClick: () => calls.add('click')),
        FloconTextField(
          id: 'rename',
          label: 'R',
          value: '',
          onSubmitted: (v) => calls.add('text:$v'),
        ),
        FloconCheckBox(
          id: 'premium',
          label: 'P',
          value: false,
          onChanged: (v) => calls.add('check:$v'),
        ),
      ]),
    ]);
    await settle();

    plugin.onMessageReceived(_msg('on_click', 'main_go'));
    plugin.onMessageReceived(_msg('on_click', '"main_go"'));
    plugin.onMessageReceived(
      _msg('on_text_field_submitted', {'id': 'main_rename', 'value': 'Flo'}),
    );
    plugin.onMessageReceived(
      _msg('on_check_box_value_changed', {'id': 'main_premium', 'value': true}),
    );
    plugin.onMessageReceived(_msg('on_click', 'unknown'));
    plugin.onMessageReceived(_msg('on_click', 'main_rename')); // not a button
    expect(calls, ['click', 'click', 'text:Flo', 'check:true']);
  });

  test('a form gives back the values keyed by the ids of the app', () async {
    Map<String, String>? submitted;
    plugin.dashboard('main', [
      FloconForm(
        'Create',
        [
          FloconTextField(id: 'name', label: 'Name', value: ''),
          FloconCheckBox(id: 'admin', label: 'Admin', value: false),
        ],
        submitText: 'Create',
        onSubmitted: (values) => submitted = values,
      ),
    ]);
    await settle();
    plugin.onMessageReceived(
      _msg('on_form_submitted', {
        'id': 'main_form_Create',
        'values': {'main_name': 'Flo', 'main_admin': 'true', 'other': 'x'},
      }),
    );
    expect(submitted, {'name': 'Flo', 'admin': 'true', 'other': 'x'});
  });

  test('a section follows a ValueListenable, the dashboard is sent again', () async {
    final user = ValueNotifier('Flo');
    final handle = plugin.dashboard('main', [
      FloconSection.listen<String>(
        'User',
        user,
        (name) => [FloconText('name', name)],
      ),
      FloconSection('Static', const [FloconLabel('x')]),
    ]);
    await settle();
    expect(sender.sent, hasLength(1));
    user.value = 'David';
    await settle();
    expect(sender.sent, hasLength(2));
    final text =
        (((sender.sent.last.body['containers'] as List).first
                as Map)['elements']
            as List)
        .first;
    expect((text as Map)['text'], {'label': 'name', 'value': 'David'});

    await handle.dispose();
    user.value = 'Nobody';
    await settle();
    expect(sender.sent, hasLength(2));
  });

  test('a stream section waits for its first value before the dashboard is sent', () async {
    final controller = StreamController<int>();
    plugin.dashboard('main', [
      FloconSection.fromStream<int>(
        'Count',
        controller.stream,
        (n) => [FloconText('n', '$n')],
      ),
      FloconSection('Static', const []),
    ]);
    await settle();
    expect(sender.sent, isEmpty);
    controller.add(1);
    await settle();
    expect(sender.sent, hasLength(1));
    await controller.close();
  });

  test('the dashboards are sent again on connection', () async {
    plugin.dashboard('a', [FloconSection('S', const [])]);
    plugin.dashboard('b', [FloconSection('S', const [])]);
    await settle();
    sender.sent.clear();
    plugin.onConnectedToServer();
    expect(sender.sent.map((m) => m.body['dashboardId']), ['a', 'b']);
  });

  test('an empty dashboard is sent without containers', () {
    plugin.dashboard('empty', const []);
    expect(sender.sent.single.body['containers'], isEmpty);
  });

  test('unreadable or unknown messages are ignored', () {
    plugin.onMessageReceived(_msg('on_text_field_submitted', 'nope'));
    plugin.onMessageReceived(_msg('nope', {}));
  });

  test('the facade does nothing before initialize', () async {
    final handle = floconDashboard('main', [FloconSection('S', const [])]);
    await handle.dispose();
  });
}
