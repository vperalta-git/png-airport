part of 'mobile_demo_app.dart';

class DemoBookings extends StatefulWidget {
  final PngApiClient api;
  final Map<String, dynamic> profile;
  const DemoBookings({super.key, required this.api, required this.profile});
  @override
  State<DemoBookings> createState() => _DemoBookingsState();
}

class _DemoBookingsState extends State<DemoBookings> {
  List<BookingV1> bookings = [];
  Map<String, dynamic> catalog = {}, summary = {};
  List<dynamic> drivers = [], vehicles = [];
  bool loading = false, first = true;
  String? error;
  String filter = 'Active';
  String lane = 'Arrivals';
  String get laneDirection => lane == 'Departures'
      ? 'OUTBOUND_CITY_TO_AIRPORT'
      : 'INBOUND_AIRPORT_TO_CITY';
  Map get laneSummary => lane == 'All transfers'
      ? summary
      : (summary[lane.toLowerCase()] as Map? ?? {});
  DateTime? lastRead;
  Timer? timer;
  int requestId = 0;
  String get role => widget.profile['role'] as String;
  bool get staff => ['DISPATCHER', 'SUPERVISOR', 'SUPER_ADMIN'].contains(role);
  @override
  void initState() {
    super.initState();
    load();
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!loading && (ModalRoute.of(context)?.isCurrent ?? false)) load();
    });
  }

  @override
  void dispose() {
    requestId++;
    timer?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    if (loading) return;
    final version = ++requestId;
    setState(() => loading = true);
    try {
      final data = await Future.wait([
        widget.api.get(lane == 'All transfers'
            ? '/api/v1/bookings'
            : '/api/v1/bookings/${lane.toLowerCase()}'),
        widget.api.get('/api/v1/config'),
        if (staff) widget.api.get('/api/v1/reports/dashboard'),
        if (staff || role == 'DRIVER')
          widget.api.get('/api/v1/resources/drivers'),
        if (staff) widget.api.get('/api/v1/resources/vehicles')
      ]);
      final items = (data[0] as List)
          .map((v) => BookingV1.fromJson(v as Map<String, dynamic>))
          .toList();
      if (!mounted || version != requestId) return;
      setState(() {
        bookings = items;
        catalog = data[1] as Map<String, dynamic>;
        int index = 2;
        if (staff) summary = data[index++] as Map<String, dynamic>;
        if (staff || role == 'DRIVER') drivers = data[index++] as List;
        if (staff) vehicles = data[index] as List;
        error = null;
        lastRead = DateTime.now();
        first = false;
      });
    } catch (e) {
      if (mounted && version == requestId) {
        setState(() => error = readableError(e));
      }
    } finally {
      if (mounted && version == requestId) setState(() => loading = false);
    }
  }

  Future<void> create() async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => DemoBookingForm(
            api: widget.api,
            profile: widget.profile,
            catalog: catalog,
            initialDirection: laneDirection,
            lockDirection: true)));
    if (mounted) load();
  }

  Future<void> detail(BookingV1 b) async {
    await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => DemoBookingDetail(
            api: widget.api, profile: widget.profile, initial: b)));
    if (mounted) load();
  }

  Future<void> duty(bool value) async {
    if (loading) return;
    setState(() => loading = true);
    try {
      await widget.api.patch(
          '/api/v1/resources/drivers/${widget.profile['uid']}',
          {'available': value});
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) {
        setState(() => loading = false);
        load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = bookings.where((b) {
      if (lane != 'All transfers' &&
          b.input.toJson()['direction'] != laneDirection) {
        return false;
      }
      final done = ['COMPLETED', 'CLOSED', 'CANCELLED'].contains(b.status);
      return filter == 'All' || (filter == 'History' ? done : !done);
    }).toList();
    return RefreshIndicator(
        onRefresh: load,
        child: DemoContentList(children: [
          Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: AviationColors.primaryNavy,
                  borderRadius: BorderRadius.circular(18)),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(widget.profile['fullName'] as String,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(
                          role == 'PASSENGER'
                              ? 'Your Lae airport transfers'
                              : role == 'DRIVER'
                                  ? 'Your assigned trips'
                                  : 'Lae operations',
                          style: const TextStyle(color: Color(0xFFCBD5E1))),
                      const SizedBox(height: 10),
                      const Text('LAE / NADZAB · PAPUA NEW GUINEA',
                          style: TextStyle(
                              color: AviationColors.goldTrim,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: .8)),
                    ])),
                IconButton(
                    tooltip: 'Refresh',
                    onPressed: loading ? null : load,
                    icon: const Icon(Icons.refresh, color: Colors.white))
              ])),
          if (loading)
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator()),
          if (lastRead != null)
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                    'Last confirmed update: ${DateFormat('HH:mm:ss').format(lastRead!.toUtc().add(const Duration(hours: 10)))} PNG',
                    style: Theme.of(context).textTheme.bodySmall)),
          if (error != null)
            DemoMessage('${error!} Displayed records may be out of date.',
                retry: loading ? null : load),
          const SizedBox(height: 12),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Arrivals', 'Departures', 'All transfers']
                  .map((value) => ChoiceChip(
                        key: ValueKey('transfer-lane-$value'),
                        label: Text(value,
                            style: TextStyle(
                                color: lane == value
                                    ? Colors.white
                                    : AviationColors.primaryNavy)),
                        selectedColor: AviationColors.primaryNavy,
                        checkmarkColor: Colors.white,
                        selected: lane == value,
                        onSelected: loading
                            ? null
                            : (_) {
                                setState(() => lane = value);
                                load();
                              },
                      ))
                  .toList()),
          const SizedBox(height: 12),
          Text(
              lane == 'Arrivals'
                  ? 'Arrivals · Airport pickup → Lae destination'
                  : lane == 'Departures'
                      ? 'Departures · Lae pickup → Airport drop-off'
                      : 'All airport transfers',
              style: Theme.of(context).textTheme.titleMedium),
          if (staff)
            LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth >= 640 ? 4 : 2;
              final width =
                  (constraints.maxWidth - 10 * (columns - 1)) / columns;
              return Wrap(spacing: 10, runSpacing: 10, children: [
                _metric('Awaiting assignment',
                    laneSummary['awaitingAssignment'], width),
                _metric('Active trips', laneSummary['activeTrips'], width),
                _metric('Completed', laneSummary['completedTrips'], width),
                _metric(
                    'Payments pending', laneSummary['pendingPayments'], width)
              ]);
            }),
          if (role == 'DRIVER' && drivers.isNotEmpty)
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(children: [
                      SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('On duty'),
                          subtitle: Text(
                              drivers.first['activeBookingId'] != null
                                  ? 'Assigned work is in progress'
                                  : 'Available for dispatch when on duty'),
                          value: drivers.first['onDuty'] == true,
                          onChanged: loading ||
                                  error != null ||
                                  drivers.first['activeBookingId'] != null
                              ? null
                              : duty),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                              'Completed trips: ${drivers.first['completedTrips']}')),
                    ]))),
          if (role == 'PASSENGER')
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SizedBox(
                    height: 50,
                    child: FilledButton.icon(
                        onPressed: loading || error != null || catalog.isEmpty
                            ? null
                            : create,
                        icon: const Icon(Icons.add),
                        label: Text(lane == 'Departures'
                            ? 'Book departure transfer'
                            : 'Book arrival transfer')))),
          const SizedBox(height: 16),
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Active', 'History', 'All']
                  .map((label) => ChoiceChip(
                      label: Text(label,
                          style: TextStyle(
                              color: filter == label
                                  ? Colors.white
                                  : AviationColors.primaryNavy)),
                      selectedColor: AviationColors.primaryNavy,
                      checkmarkColor: Colors.white,
                      selected: filter == label,
                      onSelected: (_) => setState(() => filter = label)))
                  .toList()),
          const SizedBox(height: 12),
          if (first && loading)
            const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()))
          else if (first && error != null)
            const DemoEmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Reservations unavailable',
                message: 'Reconnect and refresh to load the latest records.')
          else if (visible.isEmpty)
            DemoEmptyState(
                title: 'No reservations in this view.',
                message: filter == 'History'
                    ? 'Completed and cancelled transfers will appear here.'
                    : role == 'PASSENGER'
                        ? 'Book an airport transfer to begin.'
                        : 'New work will appear here after the next refresh.')
          else
            ...visible.map((b) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                    onTap: () => detail(b),
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                const Icon(Icons.confirmation_number_outlined,
                                    size: 18, color: AviationColors.textMuted),
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(b.referenceNumber,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                                color: AviationColors
                                                    .textSecondary))),
                                const Icon(Icons.chevron_right,
                                    color: AviationColors.textMuted),
                              ]),
                              const SizedBox(height: 8),
                              Wrap(spacing: 6, runSpacing: 4, children: [
                                StatusChipV1(b.status),
                                StatusChipV1(b.paymentStatus, payment: true)
                              ]),
                              const SizedBox(height: 8),
                              Text(
                                  b.input.toJson()['direction'] ==
                                          'OUTBOUND_CITY_TO_AIRPORT'
                                      ? 'DEPARTURE · To Nadzab Airport'
                                      : 'ARRIVAL · From Nadzab Airport',
                                  style:
                                      Theme.of(context).textTheme.labelLarge),
                              const SizedBox(height: 6),
                              Text(
                                  b.input.toJson()['destinationAddress']
                                      as String,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              Row(children: [
                                const Icon(Icons.schedule_outlined,
                                    size: 17, color: AviationColors.textMuted),
                                const SizedBox(width: 6),
                                Expanded(
                                    child: Text(
                                        pngTime(
                                            b.input.toJson()['pickupDateTime']
                                                as String),
                                        style: const TextStyle(
                                            color:
                                                AviationColors.textSecondary))),
                              ]),
                              const SizedBox(height: 14),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Row(children: [
                                Expanded(
                                    child: Text(pgk(b.pricing.totalMinor),
                                        style: const TextStyle(
                                            fontSize: 19,
                                            fontWeight: FontWeight.w700,
                                            color:
                                                AviationColors.primaryNavy))),
                                const Text('View trip',
                                    style: TextStyle(
                                        color: AviationColors.primaryNavy,
                                        fontWeight: FontWeight.w600)),
                              ]),
                            ]))))),
          if (staff) ...[
            const SizedBox(height: 16),
            Text('Driver & vehicle availability',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (!first && error == null && drivers.isEmpty && vehicles.isEmpty)
              const DemoEmptyState(
                  icon: Icons.directions_car_outlined,
                  title: 'No resources in this scope',
                  message:
                      'Driver and vehicle records will appear when available.'),
            ...drivers.map((d) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.person_outline,
                    color:
                        d['available'] == true ? Colors.green : Colors.orange),
                title: Text(d['fullName'] as String),
                subtitle: Text(d['available'] == true
                    ? 'Available'
                    : d['activeBookingId'] != null
                        ? 'Assigned to active trip'
                        : d['active'] != true
                            ? 'Suspended'
                            : 'Off duty'))),
            ...vehicles.map((v) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.directions_car_outlined),
                title: Text('${v['makeModel']} • ${v['registrationPlate']}'),
                subtitle: Text(v['available'] == true
                    ? 'Available • ${v['passengerCapacity']} seats'
                    : v['activeBookingId'] != null
                        ? 'Assigned to active trip'
                        : statusName(v['status'] as String)))),
          ],
        ]));
  }

  Widget _metric(String name, dynamic value, double width) => SizedBox(
      width: width,
      child: Card(
          child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value == null ? '—' : '$value',
                        style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                            color: AviationColors.primaryNavy)),
                    const SizedBox(height: 4),
                    Text(name)
                  ]))));
}

class DemoBookingForm extends StatefulWidget {
  final PngApiClient api;
  final Map<String, dynamic> profile, catalog;
  final String initialDirection;
  final bool lockDirection;
  const DemoBookingForm(
      {super.key,
      required this.api,
      required this.profile,
      required this.catalog,
      this.initialDirection = 'INBOUND_AIRPORT_TO_CITY',
      this.lockDirection = false});
  @override
  State<DemoBookingForm> createState() => _DemoBookingFormState();
}

class _DemoBookingFormState extends State<DemoBookingForm> {
  final form = GlobalKey<FormState>(),
      destination = TextEditingController(),
      phone = TextEditingController();
  final List<TextEditingController> names = [];
  String? category;
  late String direction;
  int luggage = 1;
  late DateTime pickup;
  QuotationV1? quote;
  String? intentId, error;
  bool busy = false, uncertain = false;
  List<dynamic> get categories => widget.catalog['vehicleCategories'] as List;
  bool get locked => busy || uncertain;
  Map get selectedCategory =>
      categories.firstWhere((c) => c['id'] == category) as Map;
  int get capacity => selectedCategory['passengerCapacity'] as int;
  int get luggageCapacity => selectedCategory['luggageCapacity'] as int;
  @override
  void initState() {
    super.initState();
    direction = widget.initialDirection;
    pickup = DateTime.now().toUtc().add(const Duration(hours: 11));
    category = categories.isEmpty ? null : categories.first['id'] as String;
    names
        .add(TextEditingController(text: widget.profile['fullName'] as String));
    phone.text = widget.profile['phone'] as String? ?? '';
    destination.addListener(invalidate);
  }

  void invalidate() {
    if (quote != null && !locked && mounted) setState(() => quote = null);
  }

  @override
  void dispose() {
    destination.dispose();
    phone.dispose();
    for (final c in names) {
      c.dispose();
    }
    super.dispose();
  }

  void count(int n) {
    setState(() {
      while (names.length < n) {
        names.add(TextEditingController());
      }
      while (names.length > n) {
        names.removeLast().dispose();
      }
      quote = null;
    });
  }

  Future<void> chooseTime() async {
    final date = await showDatePicker(
        context: context,
        initialDate: pickup,
        firstDate: DateTime.now()
            .toUtc()
            .add(const Duration(hours: 10))
            .subtract(const Duration(days: 1)),
        lastDate: DateTime.now().add(const Duration(days: 365)));
    if (date == null || !mounted) return;
    final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: pickup.hour, minute: pickup.minute));
    if (time != null && mounted) {
      setState(() {
        pickup =
            DateTime(date.year, date.month, date.day, time.hour, time.minute);
        quote = null;
      });
    }
  }

  String schedule() =>
      '${DateFormat("yyyy-MM-dd'T'HH:mm:ss").format(pickup)}+10:00';
  Future<void> requestQuote() async {
    if (locked || !form.currentState!.validate() || category == null) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final input = TransferInputV1.fromJson({
        'airportId': 'airport_nadzab_lae',
        'direction': direction,
        'vehicleCategory': category,
        'securityEscortType': 'NONE',
        'pickupDateTime': schedule(),
        'destinationAddress': destination.text.trim(),
        'passengerCount': names.length,
        'luggageCount': luggage
      });
      final result = await widget.api.requestQuotationV1(input);
      if (mounted) {
        setState(() {
          quote = result;
          intentId = 'mobile-${result.id}';
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> submit() async {
    if (busy ||
        quote == null ||
        intentId == null ||
        !form.currentState!.validate()) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final value = await widget.api.post('/api/v1/bookings', {
        'schemaVersion': '1',
        'quotationId': quote!.id,
        'idempotencyKey': intentId,
        'paymentMethod': 'CASH_ON_BOARD',
        'passengers': names
            .asMap()
            .entries
            .map((entry) => {
                  'fullName': entry.value.text.trim(),
                  if (entry.key == 0 && phone.text.trim().isNotEmpty)
                    'phone': phone.text.trim()
                })
            .toList()
      });
      final saved = BookingV1.fromJson(value as Map<String, dynamic>);
      if (mounted) {
        setState(() {
          uncertain = false;
          busy = false;
        });
        Navigator.pop(context, saved);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = readableError(e);
          uncertain = e is! ApiException ||
              e.code == 'NETWORK_ERROR' ||
              e.code == 'PARSE_ERROR' ||
              (e.status ?? 0) >= 500;
          if (uncertain) {
            error =
                '$error The result is uncertain. Retry this same reservation to avoid a duplicate.';
          }
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !busy && !uncertain,
      child: Scaffold(
          appBar: AppBar(
              title: Text(direction == 'OUTBOUND_CITY_TO_AIRPORT'
                  ? 'Book departure transfer'
                  : 'Book arrival transfer')),
          body: Column(children: [
            const DemoBanner(),
            Expanded(
                child: DemoContentList(maxWidth: 720, children: [
              const Row(children: [
                Icon(Icons.flight_takeoff, color: AviationColors.goldTrim),
                SizedBox(width: 10),
                Expanded(
                    child: Text('Nadzab Tomodachi Airport (LAE)',
                        style: TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 8),
              Text(widget.catalog['pricingNotice'] as String,
                  style: const TextStyle(
                      color: AviationColors.textSecondary, height: 1.4)),
              const SizedBox(height: 18),
              if (error != null) DemoMessage(error!),
              Form(
                  key: form,
                  child: Column(children: [
                    DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: direction,
                        decoration: const InputDecoration(
                            labelText: 'Transfer direction',
                            border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(
                              value: 'INBOUND_AIRPORT_TO_CITY',
                              child: Text('Arrival · Airport pickup to Lae')),
                          DropdownMenuItem(
                              value: 'OUTBOUND_CITY_TO_AIRPORT',
                              child: Text('Departure · Lae pickup to airport'))
                        ],
                        onChanged: locked || widget.lockDirection
                            ? null
                            : (v) => setState(() {
                                  direction = v!;
                                  quote = null;
                                })),
                    const SizedBox(height: 14),
                    _field(
                        destination,
                        direction == 'INBOUND_AIRPORT_TO_CITY'
                            ? 'Destination address in Lae'
                            : 'Pickup address in Lae',
                        busy: locked,
                        mandatory: true),
                    DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: category,
                        decoration: const InputDecoration(
                            labelText: 'Vehicle category',
                            border: OutlineInputBorder()),
                        items: categories
                            .map((c) => DropdownMenuItem(
                                value: c['id'] as String,
                                child: Text(
                                    '${c['name']} • ${c['passengerCapacity']} seats')))
                            .toList(),
                        onChanged: locked
                            ? null
                            : (v) => setState(() {
                                  category = v;
                                  quote = null;
                                  while (names.length > capacity) {
                                    names.removeLast().dispose();
                                  }
                                  luggage = min(luggage, luggageCapacity);
                                })),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                          child: Text(
                              'Pickup: ${DateFormat('dd MMM yyyy, HH:mm').format(pickup)} PNG (UTC+10)')),
                      TextButton(
                          onPressed: locked ? null : chooseTime,
                          child: const Text('Change time'))
                    ]),
                    const SizedBox(height: 14),
                    Row(children: [
                      Expanded(
                          child: DropdownButtonFormField<int>(
                              key: ValueKey(
                                  'passengers-$category-${names.length}'),
                              initialValue: names.length,
                              decoration: const InputDecoration(
                                  labelText: 'Passengers'),
                              items: List.generate(
                                  capacity,
                                  (i) => DropdownMenuItem(
                                      value: i + 1, child: Text('${i + 1}'))),
                              onChanged: locked ? null : (v) => count(v!))),
                      const SizedBox(width: 18),
                      Expanded(
                          child: DropdownButtonFormField<int>(
                              key: ValueKey('luggage-$category-$luggage'),
                              initialValue: luggage,
                              decoration:
                                  const InputDecoration(labelText: 'Luggage'),
                              items: List.generate(
                                  luggageCapacity + 1,
                                  (i) => DropdownMenuItem(
                                      value: i, child: Text('$i'))),
                              onChanged: locked
                                  ? null
                                  : (v) => setState(() {
                                        luggage = v!;
                                        quote = null;
                                      }))),
                    ]),
                    const SizedBox(height: 18),
                    Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Passenger details',
                            style: Theme.of(context).textTheme.titleMedium)),
                    const SizedBox(height: 12),
                    for (int i = 0; i < names.length; i++)
                      _field(names[i], 'Passenger ${i + 1} full name',
                          busy: locked, mandatory: true),
                    _field(phone, 'Lead passenger phone',
                        busy: locked, keyboard: TextInputType.phone),
                  ])),
              if (quote == null)
                SizedBox(
                    height: 50,
                    child: FilledButton(
                        onPressed: locked ||
                                widget.catalog['pricingConfigured'] != true
                            ? null
                            : requestQuote,
                        child: Text(busy
                            ? 'Getting quote…'
                            : offlineDemoBuild
                                ? 'Get demo quote'
                                : 'Get server quote')))
              else
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(offlineDemoBuild
                                  ? 'Offline practice quote • DEMO ONLY'
                                  : 'Server quote • DEMO ONLY'),
                              const SizedBox(height: 8),
                              Text(pgk(quote!.pricing.totalMinor),
                                  style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold)),
                              Text('Valid until ${pngTime(quote!.expiresAt)}'),
                              const SizedBox(height: 8),
                              const Text(
                                  'Cash is a payment preference. This demo does not collect or confirm payment.'),
                              const SizedBox(height: 18),
                              SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: FilledButton(
                                      onPressed: busy ? null : submit,
                                      child: Text(busy
                                          ? 'Saving…'
                                          : uncertain
                                              ? 'Retry same reservation'
                                              : 'Confirm demo reservation'))),
                            ]))),
            ]))
          ])));
}

class DemoBookingDetail extends StatefulWidget {
  final PngApiClient api;
  final Map<String, dynamic> profile;
  final BookingV1 initial;
  const DemoBookingDetail(
      {super.key,
      required this.api,
      required this.profile,
      required this.initial});
  @override
  State<DemoBookingDetail> createState() => _DemoBookingDetailState();
}

class _DemoBookingDetailState extends State<DemoBookingDetail> {
  late BookingV1 booking;
  Map<String, dynamic>? assignment, credential;
  List<dynamic> events = [], drivers = [], vehicles = [];
  bool reading = false, busy = false;
  String? error;
  Timer? timer;
  String get role => widget.profile['role'] as String;
  bool get staff => ['DISPATCHER', 'SUPERVISOR', 'SUPER_ADMIN'].contains(role);
  bool get manager => ['SUPERVISOR', 'SUPER_ADMIN'].contains(role);
  bool get early => [
        'BOOKING_REQUESTED',
        'AVAILABILITY_CONFIRMED',
        'CONFIRMED',
        'DISPATCHED'
      ].contains(booking.status);
  bool get enabled => !busy && !reading && error == null;
  @override
  void initState() {
    super.initState();
    booking = widget.initial;
    load();
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!busy && !reading && (ModalRoute.of(context)?.isCurrent ?? false)) {
        load();
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    if (reading || busy) return;
    setState(() => reading = true);
    try {
      final detail =
          await widget.api.get('/api/v1/bookings/${booking.id}/details')
              as Map<String, dynamic>;
      final current =
          BookingV1.fromJson(detail['booking'] as Map<String, dynamic>);
      Map<String, dynamic>? code;
      List<dynamic> nextDrivers = [], nextVehicles = [];
      if (role == 'PASSENGER') {
        code = await widget.api
                .get('/api/v1/bookings/${booking.id}/pickup-credential')
            as Map<String, dynamic>;
      }
      if (staff) {
        final data = await Future.wait([
          widget.api.get('/api/v1/resources/drivers'),
          widget.api.get('/api/v1/resources/vehicles')
        ]);
        nextDrivers = data[0] as List;
        nextVehicles = data[1] as List;
      }
      if (mounted) {
        setState(() {
          booking = current;
          assignment = detail['assignmentInfo'] as Map<String, dynamic>?;
          events = detail['events'] as List;
          credential = code;
          drivers = nextDrivers;
          vehicles = nextVehicles;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) setState(() => reading = false);
    }
  }

  Future<void> action(String path, Map<String, dynamic> values,
      {bool patch = false}) async {
    if (!enabled) return;
    setState(() => busy = true);
    try {
      final response = patch
          ? await widget.api
              .patch(path, {...values, 'expectedRevision': booking.revision})
          : await widget.api
              .post(path, {...values, 'expectedRevision': booking.revision});
      final next = BookingV1.fromJson(response as Map<String, dynamic>);
      if (mounted) setState(() => booking = next);
    } catch (e) {
      if (mounted) setState(() => error = readableError(e));
    } finally {
      if (mounted) {
        final actionError = error;
        setState(() => busy = false);
        await load();
        if (mounted && actionError != null) setState(() => error = actionError);
      }
    }
  }

  Future<void> setStatus(String status) async {
    if (status == 'CANCELLED' || status == 'COMPLETED') {
      final yes = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                  title: Text(status == 'CANCELLED'
                      ? 'Cancel this reservation?'
                      : 'Complete this trip?'),
                  content: Text(status == 'CANCELLED'
                      ? offlineDemoBuild
                          ? 'The practice cancellation will be saved on this phone.'
                          : 'The cancellation will be recorded by the backend.'
                      : 'Confirm arrival and trip completion. Payment will remain separate.'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Keep trip')),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Confirm'))
                  ]));
      if (yes != true) return;
    }
    await action('/api/v1/bookings/${booking.id}/status', {'status': status},
        patch: true);
  }

  Future<void> assign() async {
    final candidates = drivers
        .where((d) =>
            d['active'] == true &&
            d['onDuty'] == true &&
            (d['available'] == true || d['activeBookingId'] == booking.id))
        .toList();
    final cars = vehicles
        .where((v) =>
            v['status'] == 'ACTIVE' &&
            v['category'] == booking.input.toJson()['vehicleCategory'] &&
            (v['available'] == true || v['activeBookingId'] == booking.id))
        .toList();
    if (candidates.isEmpty || cars.isEmpty) {
      setState(() => error =
          'No eligible driver and matching vehicle are available. Refresh availability or update the fleet.');
      return;
    }
    final result =
        await _recordDialog(context, title: 'Assign driver & vehicle', fields: [
      _RecordField('driverId', 'Driver', choices: {
        for (final d in candidates) d['id'] as String: d['fullName'] as String
      }),
      _RecordField('vehicleId', 'Vehicle', choices: {
        for (final v in cars)
          v['id'] as String: '${v['makeModel']} • ${v['registrationPlate']}'
      }),
    ]);
    if (result != null && mounted) {
      await action('/api/v1/dispatch/${booking.id}/assign', result);
    }
  }

  Future<void> accept() async {
    final checks = await showDialog<bool>(
        context: context, builder: (ctx) => const _InspectionDialog());
    if (checks == true && mounted) {
      await action('/api/v1/dispatch/${booking.id}/acknowledge', {
        'inspection': {
          'seatbelts': true,
          'tyres': true,
          'fuel': true,
          'radio': true
        }
      });
    }
  }

  Future<void> verify() async {
    final result = await _recordDialog(context,
        title: 'Verify passenger pickup',
        fields: [_RecordField('code', 'Customer pickup code', numeric: true)]);
    if (result != null && mounted) {
      await action('/api/v1/bookings/${booking.id}/verify-passenger', result);
    }
  }

  Future<void> reset() async {
    final result = await _recordDialog(context,
        title: 'Reissue pickup code',
        fields: [_RecordField('reason', 'Reason for reissue')]);
    if (result != null && mounted) {
      await action('/api/v1/bookings/${booking.id}/reset-otp', result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final input = booking.input.toJson();
    final departure = input['direction'] == 'OUTBOUND_CITY_TO_AIRPORT';
    final next = {
      'DRIVER_EN_ROUTE': departure ? 'AT_PICKUP' : 'AT_AIRPORT',
      'PASSENGER_VERIFIED': 'TRANSFER_IN_PROGRESS',
      'TRANSFER_IN_PROGRESS': 'ARRIVED_DESTINATION',
      'ARRIVED_DESTINATION': 'COMPLETED'
    }[booking.status];
    final nextLabel = {
      'AT_AIRPORT': 'Arrived at airport pickup',
      'AT_PICKUP': 'Arrived at customer pickup',
      'TRANSFER_IN_PROGRESS': 'Start transfer',
      'ARRIVED_DESTINATION': departure
          ? 'Arrived at airport drop-off'
          : 'Arrived at Lae destination',
      'COMPLETED': 'Complete trip'
    }[next];
    return Scaffold(
        appBar: AppBar(title: Text(booking.referenceNumber), actions: [
          IconButton(
              tooltip: 'Refresh trip',
              onPressed: busy || reading ? null : load,
              icon: const Icon(Icons.refresh))
        ]),
        body: Column(children: [
          const DemoBanner(),
          Expanded(
              child: DemoContentList(maxWidth: 720, children: [
            if (reading || busy) const LinearProgressIndicator(),
            if (error != null)
              DemoMessage(error!, retry: busy || reading ? null : load),
            Wrap(spacing: 8, runSpacing: 6, children: [
              StatusChipV1(booking.status),
              StatusChipV1(booking.paymentStatus, payment: true)
            ]),
            const SizedBox(height: 14),
            Text(
                departure
                    ? 'Departure · Lae to airport'
                    : 'Arrival · Airport to Lae',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
                departure
                    ? 'Pickup: ${input['destinationAddress']}\nDrop-off: Nadzab Tomodachi Airport (LAE)'
                    : 'Pickup: Nadzab Tomodachi Airport (LAE)\nDrop-off: ${input['destinationAddress']}',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(pngTime(input['pickupDateTime'] as String)),
            Text(
                'Nadzab / Lae • ${statusName(input['vehicleCategory'] as String)}'),
            const SizedBox(height: 12),
            Text(pgk(booking.pricing.totalMinor),
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const Text('DEMO fare. No payment has been collected or verified.'),
            const Divider(height: 32),
            Text('Passengers', style: Theme.of(context).textTheme.titleMedium),
            ...booking.passengers.map((p) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline),
                title: Text(p['fullName'] as String),
                subtitle:
                    p['phone'] != null ? Text(p['phone'] as String) : null)),
            const Divider(height: 24),
            Text('Driver & vehicle',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(assignment?['driverName'] as String? ?? 'Awaiting assignment'),
            if (assignment?['driverPhone'] != null)
              Text(assignment!['driverPhone'] as String),
            if (assignment?['vehicleName'] != null)
              Text(
                  '${assignment!['vehicleName']} • ${assignment!['registrationPlate']}'),
            if (role == 'PASSENGER')
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Passenger pickup code'),
                            const SizedBox(height: 8),
                            if (credential?['available'] == true) ...[
                              Text(credential!['code'] as String,
                                  style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 5)),
                              Text(
                                  'Expires ${pngTime(credential!['expiresAt'] as String)}'),
                              const Text(
                                  'Share this with your assigned driver at pickup only.')
                            ] else
                              const Text(
                                  'No active code. It may have been used, expired or locked.'),
                          ]))),
            const SizedBox(height: 16),
            if (staff && early)
              _actionButton(
                  booking.dispatch == null
                      ? 'Assign driver & vehicle'
                      : 'Reassign driver & vehicle',
                  assign),
            if (role == 'DRIVER' && booking.status == 'DISPATCHED')
              _actionButton(
                  booking.dispatch?['acceptedAt'] == null
                      ? 'Accept assignment & pre-trip checks'
                      : departure
                          ? 'Drive to customer pickup'
                          : 'Drive to airport pickup',
                  booking.dispatch?['acceptedAt'] == null
                      ? accept
                      : () => setStatus('DRIVER_EN_ROUTE')),
            if (role == 'DRIVER' &&
                booking.status == (departure ? 'AT_PICKUP' : 'AT_AIRPORT'))
              _actionButton('Verify passenger pickup', verify),
            if (role == 'DRIVER' && next != null)
              _actionButton(nextLabel!, () => setStatus(next)),
            if ((role == 'PASSENGER' || staff) && early)
              _actionButton('Cancel reservation', () => setStatus('CANCELLED'),
                  outlined: true),
            if (manager && booking.status == 'COMPLETED')
              _actionButton(
                  'Close completed reservation', () => setStatus('CLOSED')),
            if (manager &&
                booking.status == (departure ? 'AT_PICKUP' : 'AT_AIRPORT'))
              _actionButton('Reissue pickup code', reset, outlined: true),
            const SizedBox(height: 20),
            Text('Trip activity',
                style: Theme.of(context).textTheme.titleMedium),
            if (events.isEmpty) const Text('No activity loaded.'),
            ...events.map((e) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.history),
                title: Text(statusName(e['description'] as String)),
                subtitle: Text(
                    '${pngTime(e['timestamp'] as String)} • ${roleName(e['actorRole'] as String)}'))),
          ]))
        ]));
  }

  Widget _actionButton(String title, Future<void> Function() callback,
          {bool outlined = false}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
              height: 52,
              width: double.infinity,
              child: outlined
                  ? OutlinedButton(
                      onPressed: enabled ? callback : null, child: Text(title))
                  : FilledButton(
                      onPressed: enabled ? callback : null,
                      child: Text(title))));
}

class _InspectionDialog extends StatefulWidget {
  const _InspectionDialog();
  @override
  State<_InspectionDialog> createState() => _InspectionDialogState();
}

class _InspectionDialogState extends State<_InspectionDialog> {
  final checked = [false, false, false, false];
  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('Pre-trip checks'),
          content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Confirm these checks before accepting the assignment.'),
            for (int i = 0; i < 4; i++)
              CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text([
                    'Seatbelts checked',
                    'Tyres checked',
                    'Fuel checked',
                    'Radio / phone checked'
                  ][i]),
                  value: checked[i],
                  onChanged: (v) => setState(() => checked[i] = v!)),
          ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: checked.every((v) => v)
                    ? () => Navigator.pop(context, true)
                    : null,
                child: const Text('Accept assignment'))
          ]);
}
