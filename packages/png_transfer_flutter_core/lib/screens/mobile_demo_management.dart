part of 'mobile_demo_app.dart';

class _RecordField {
  final String key, label;
  final String initial;
  final Map<String, String>? choices;
  final bool secret, numeric, optional;
  const _RecordField(this.key, this.label,
      {this.initial = '',
      this.choices,
      this.secret = false,
      this.numeric = false,
      this.optional = false});
}

Future<Map<String, dynamic>?> _recordDialog(BuildContext context,
        {required String title, required List<_RecordField> fields}) =>
    showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => _RecordDialog(title: title, fields: fields));

class _RecordDialog extends StatefulWidget {
  final String title;
  final List<_RecordField> fields;
  const _RecordDialog({required this.title, required this.fields});
  @override
  State<_RecordDialog> createState() => _RecordDialogState();
}

class _RecordDialogState extends State<_RecordDialog> {
  final form = GlobalKey<FormState>();
  final Map<String, TextEditingController> controllers = {};
  final Map<String, String> selections = {};
  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      if (field.choices != null) {
        selections[field.key] = field.choices!.containsKey(field.initial)
            ? field.initial
            : field.choices!.keys.first;
      } else {
        controllers[field.key] = TextEditingController(text: field.initial);
      }
    }
  }

  @override
  void dispose() {
    for (final c in controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void submit() {
    if (!form.currentState!.validate()) return;
    Navigator.pop(context, <String, dynamic>{
      ...selections,
      for (final entry in controllers.entries)
        entry.key: widget.fields.firstWhere((f) => f.key == entry.key).secret
            ? entry.value.text
            : entry.value.text.trim()
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: Text(widget.title),
          content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                  child: Form(
                      key: form,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        for (final field in widget.fields)
                          if (field.choices != null)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: DropdownButtonFormField<String>(
                                    initialValue: selections[field.key],
                                    decoration: InputDecoration(
                                        labelText: field.label,
                                        border: const OutlineInputBorder()),
                                    isExpanded: true,
                                    items: field.choices!.entries
                                        .map((e) => DropdownMenuItem(
                                            value: e.key,
                                            child: Text(e.value,
                                                maxLines: 2,
                                                overflow:
                                                    TextOverflow.ellipsis)))
                                        .toList(),
                                    onChanged: (v) => setState(
                                        () => selections[field.key] = v!)))
                          else
                            _field(controllers[field.key]!, field.label,
                                mandatory: !field.optional,
                                secret: field.secret,
                                keyboard: field.numeric
                                    ? TextInputType.number
                                    : field.key == 'email'
                                        ? TextInputType.emailAddress
                                        : field.key == 'phone'
                                            ? TextInputType.phone
                                            : null, validate: (v) {
                              if (!field.optional &&
                                  (v == null || v.trim().isEmpty)) {
                                return 'Enter ${field.label.toLowerCase()}';
                              }
                              if (field.key == 'password' &&
                                  (v?.length ?? 0) < 10) {
                                return 'Use at least 10 characters';
                              }
                              if (field.key == 'email' &&
                                  !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                      .hasMatch(v ?? '')) {
                                return 'Enter a valid email address';
                              }
                              if (field.key == 'code' &&
                                  !RegExp(r'^\d{6}$').hasMatch(v ?? '')) {
                                return 'Enter the six digit pickup code';
                              }
                              return null;
                            }),
                      ])))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel')),
            FilledButton(onPressed: submit, child: const Text('Continue'))
          ]);
}

class DemoManagement extends StatefulWidget {
  final PngApiClient api;
  final Map<String, dynamic> profile;
  const DemoManagement({super.key, required this.api, required this.profile});
  @override
  State<DemoManagement> createState() => _DemoManagementState();
}

class _DemoManagementState extends State<DemoManagement> {
  List<dynamic> users = [], vehicles = [], audit = [], drivers = [];
  bool loading = false, busy = false, loaded = false;
  String? error;
  int tab = 0;
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (loading || busy) return;
    setState(() => loading = true);
    try {
      final data = await Future.wait([
        widget.api.get('/api/v1/users'),
        widget.api.get('/api/v1/resources/vehicles'),
        widget.api.get('/api/v1/reports/audit'),
        widget.api.get('/api/v1/resources/drivers')
      ]);
      if (mounted) {
        setState(() {
          users = data[0] as List;
          vehicles = data[1] as List;
          audit = data[2] as List;
          drivers = data[3] as List;
          loaded = true;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> save(String path, Map<String, dynamic> data,
      {bool patch = false}) async {
    if (busy || loading) return;
    setState(() => busy = true);
    String? failure;
    try {
      if (patch) {
        await widget.api.patch(path, data);
      } else {
        await widget.api.post(path, data);
      }
    } catch (e) {
      failure = readableError(e);
    } finally {
      if (mounted) {
        setState(() => busy = false);
        await load();
        if (mounted && failure != null) setState(() => error = failure);
      }
    }
  }

  Future<void> addStaff() async {
    final data = await _recordDialog(context,
        title: 'Create staff account',
        fields: const [
          _RecordField('fullName', 'Full name'),
          _RecordField('email', 'Email'),
          _RecordField('password', 'Initial password', secret: true),
          _RecordField('phone', 'Phone (+675 or country code)', optional: true),
          _RecordField('role', 'Role', choices: {
            'DISPATCHER': 'Control Room',
            'DRIVER': 'Driver',
            'SUPERVISOR': 'Supervisor'
          }),
        ]);
    if (data != null && mounted) await save('/api/v1/users', data);
  }

  Future<void> editUser(Map<String, dynamic> user) async {
    final data = await _recordDialog(context, title: 'Edit account', fields: [
      _RecordField('fullName', 'Full name',
          initial: user['fullName'] as String),
      _RecordField('phone', 'Phone',
          initial: user['phone'] as String? ?? '', optional: true),
      _RecordField('active', 'Account status',
          initial: user['active'] == true ? 'true' : 'false',
          choices: const {'true': 'Active', 'false': 'Suspended'}),
    ]);
    if (data != null && mounted) {
      await save('/api/v1/users/${user['uid']}',
          {...data, 'active': data['active'] == 'true'},
          patch: true);
    }
  }

  Future<void> addVehicle() async {
    final data =
        await _recordDialog(context, title: 'Add fleet vehicle', fields: const [
      _RecordField('makeModel', 'Vehicle name / model'),
      _RecordField('registrationPlate', 'Registration plate'),
      _RecordField('category', 'Category', choices: {
        'STANDARD_SEDAN': 'Standard sedan (3 passengers)',
        'EXECUTIVE_SUV': 'SUV (5 passengers)'
      }),
    ]);
    if (data != null && mounted) await save('/api/v1/resources/vehicles', data);
  }

  Future<void> editVehicle(Map<String, dynamic> vehicle) async {
    final data =
        await _recordDialog(context, title: 'Edit fleet vehicle', fields: [
      _RecordField('makeModel', 'Vehicle name / model',
          initial: vehicle['makeModel'] as String),
      _RecordField('status', 'Status',
          initial: vehicle['status'] as String,
          choices: const {
            'ACTIVE': 'Active',
            'MAINTENANCE': 'Maintenance',
            'INACTIVE': 'Inactive'
          }),
    ]);
    if (data != null && mounted) {
      await save('/api/v1/resources/vehicles/${vehicle['id']}', data,
          patch: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = !busy && !loading && error == null;
    return RefreshIndicator(
        onRefresh: load,
        child: DemoContentList(children: [
          Row(children: [
            Expanded(
                child: Text('Operations management',
                    style: Theme.of(context).textTheme.titleLarge)),
            IconButton(
                tooltip: 'Refresh records',
                onPressed: loading || busy ? null : load,
                icon: const Icon(Icons.refresh))
          ]),
          if (loading || busy) const LinearProgressIndicator(),
          if (error != null)
            DemoMessage('${error!} Refresh to confirm the latest records.',
                retry: loading || busy ? null : load),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (int i = 0; i < 3; i++)
              ChoiceChip(
                  label: Text(['Accounts', 'Fleet', 'Audit'][i]),
                  selected: tab == i,
                  onSelected: (_) => setState(() => tab = i))
          ]),
          const SizedBox(height: 16),
          if (tab == 0) ...[
            SizedBox(
                height: 50,
                child: FilledButton.icon(
                    onPressed: enabled ? addStaff : null,
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text('Create staff account'))),
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(offlineDemoBuild
                    ? 'New practice drivers must go on duty before dispatch. Changes are saved only in this offline demo.'
                    : 'New drivers must go on duty before dispatch. Account roles and scope are enforced by the server.')),
            if (loaded && users.isEmpty)
              const DemoEmptyState(
                  icon: Icons.people_outline,
                  title: 'No accounts found in your scope.',
                  message:
                      'Create a staff account to start managing your team.'),
            ...users.map((raw) {
              final user = raw as Map<String, dynamic>;
              final found =
                  drivers.where((d) => d['id'] == user['uid']).toList();
              final driver = found.isEmpty ? null : found.first;
              return Card(
                  child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(children: [
                        ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.person_outline),
                            title: Text(user['fullName'] as String),
                            subtitle: Text(
                                '${roleName(user['role'] as String)} • ${user['active'] == true ? 'Active' : 'Suspended'}\n${user['email']}'),
                            trailing: IconButton(
                                tooltip: 'Edit account',
                                onPressed:
                                    enabled ? () => editUser(user) : null,
                                icon: const Icon(Icons.edit_outlined))),
                        if (driver != null)
                          SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Driver on duty'),
                              subtitle: Text(driver['activeBookingId'] != null
                                  ? 'Assigned to an active trip'
                                  : '${driver['completedTrips']} completed trips'),
                              value: driver['onDuty'] == true,
                              onChanged: enabled &&
                                      driver['activeBookingId'] == null &&
                                      user['active'] == true
                                  ? (v) => save(
                                      '/api/v1/resources/drivers/${user['uid']}',
                                      {'available': v},
                                      patch: true)
                                  : null),
                      ])));
            }),
          ],
          if (tab == 1) ...[
            SizedBox(
                height: 50,
                child: FilledButton.icon(
                    onPressed: enabled ? addVehicle : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Add fleet vehicle'))),
            const SizedBox(height: 12),
            if (loaded && vehicles.isEmpty)
              const DemoEmptyState(
                  icon: Icons.directions_car_outlined,
                  title: 'No fleet vehicles recorded.',
                  message: 'Add a vehicle to make it available for dispatch.'),
            ...vehicles.map((raw) {
              final v = raw as Map<String, dynamic>;
              return Card(
                  child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: const Icon(Icons.directions_car_outlined),
                      title:
                          Text('${v['makeModel']} • ${v['registrationPlate']}'),
                      subtitle: Text(
                          '${statusName(v['category'] as String)} • ${v['passengerCapacity']} seats\n${v['activeBookingId'] != null ? 'Assigned to active trip' : statusName(v['status'] as String)}'),
                      trailing: IconButton(
                          tooltip: 'Edit vehicle',
                          onPressed: enabled && v['activeBookingId'] == null
                              ? () => editVehicle(v)
                              : null,
                          icon: const Icon(Icons.edit_outlined))));
            }),
          ],
          if (tab == 2) ...[
            const Text(
                'Most recent 200 audit entries in your organization, branch and airport scope.'),
            const SizedBox(height: 12),
            if (loaded && audit.isEmpty)
              const DemoEmptyState(
                  icon: Icons.fact_check_outlined,
                  title: 'No audit activity recorded.',
                  message:
                      'Verified account and trip actions will appear here.'),
            ...audit.map((a) => Card(
                child: ListTile(
                    leading: const Icon(Icons.fact_check_outlined),
                    title: Text(statusName(a['action'] as String)),
                    subtitle: Text(
                        '${pngTime(a['timestamp'] as String)}\nActor: ${a['actorId']}\nRecord: ${a['resourceId'] ?? a['bookingId'] ?? '—'}')))),
          ],
        ]));
  }
}
