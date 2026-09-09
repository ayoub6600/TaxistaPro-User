part of '../drop_loc_select.dart';

mixin _DropLocationController on State<DropLocation>, WidgetsBindingObserver {
  GoogleMapController? _controller;
  final fm.MapController _fmController = fm.MapController();
  late PermissionStatus permission;
  Location location = Location();
  String _state = '';
  bool _isLoading = false;
  dynamic _sessionToken;
  LatLng _center = const LatLng(41.4219057, -102.0840772);
  LatLng _centerLocation = const LatLng(41.4219057, -102.0840772);
  TextEditingController search = TextEditingController();
  String favNameText = '';
  bool _locationDenied = false;
  bool favAddressAdd = false;
  bool _getDropDetails = false;
  TextEditingController buyerName = TextEditingController();
  TextEditingController buyerNumber = TextEditingController();
  TextEditingController instructions = TextEditingController();
  final _debouncer = Debouncer(milliseconds: 1000);
  bool useMyDetails = false;
  bool useMyAddress = false;
  LatLng? _lastRequestedLocation;
  bool _isMapMoving = false;

  void _onMapCreated(GoogleMapController controller) {
    if (!mounted) {
      controller.dispose();
      return;
    }
    setState(() {
      _controller = controller;
      _controller?.setMapStyle(mapStyle);
    });
  }

  Future<void> _settleMapSelection() async {
    if (!mounted) return;
    if (_isMapMoving) setState(() => _isMapMoving = false);

    final requestedLocation = _centerLocation;
    if (_lastRequestedLocation == requestedLocation &&
        dropAddressConfirmation.isNotEmpty) {
      return;
    }
    _lastRequestedLocation = requestedLocation;

    if (useMyAddress) {
      setState(() {
        _center = requestedLocation;
        useMyAddress = false;
      });
      return;
    }

    final address = await geoCoding(
      requestedLocation.latitude,
      requestedLocation.longitude,
    );
    if (!mounted || _centerLocation != requestedLocation) return;

    setState(() {
      _center = requestedLocation;
      if (address != null && address.trim().isNotEmpty) {
        dropAddressConfirmation = address.trim();
      }
    });
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    dropAddressConfirmation = '';
    useMyDetails = false;

    getLocs();
    super.initState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (isDarkTheme == true) {
      await rootBundle.loadString('assets/dark.json').then((value) {
        mapStyle = value;
      });
    } else {
      await rootBundle.loadString('assets/map_style_black.json').then((value) {
        mapStyle = value;
      });
    }
    if (state == AppLifecycleState.resumed) {
      if (_controller != null) {
        _controller?.setMapStyle(mapStyle);
        valueNotifierHome.incrementNotifier();
      }
      if (locationAllowed == true) {
        if (positionStream == null || positionStream!.isPaused) {
          positionStreamData();
        }
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _controller = null;
    search.dispose();
    buyerName.dispose();
    buyerNumber.dispose();
    instructions.dispose();

    super.dispose();
  }

  getLocs() async {
    permission = await location.hasPermission();
    if (!mounted) return;

    if (permission == PermissionStatus.denied ||
        permission == PermissionStatus.deniedForever) {
      setState(() {
        _state = '3';
        _isLoading = false;
      });
    } else if (permission == PermissionStatus.granted ||
        permission == PermissionStatus.grantedLimited) {
      var locs = await geolocs.Geolocator.getLastKnownPosition();
      if (!mounted) return;
      if (addressList.length != 2 && widget.from == null) {
        if (locs != null) {
          setState(() {
            _center = LatLng(double.parse(locs.latitude.toString()),
                double.parse(locs.longitude.toString()));
            _centerLocation = LatLng(double.parse(locs.latitude.toString()),
                double.parse(locs.longitude.toString()));
          });
        } else {
          var loc = await geolocs.Geolocator.getCurrentPosition(
              desiredAccuracy: geolocs.LocationAccuracy.low);
          if (!mounted) return;
          setState(() {
            _center = LatLng(double.parse(loc.latitude.toString()),
                double.parse(loc.longitude.toString()));
            _centerLocation = LatLng(double.parse(loc.latitude.toString()),
                double.parse(loc.longitude.toString()));
          });
        }
        setState(() {
          _center = addressList[0].latlng;
          dropAddressConfirmation = addressList[0].address;
        });
      } else if (widget.from != null &&
          widget.from != 'add stop' &&
          widget.from != 'favourite') {
        setState(() {
          buyerName.text = addressList[widget.from].name.toString();
          buyerNumber.text = addressList[widget.from].number.toString();
          instructions.text = (addressList[widget.from].instructions != null)
              ? addressList[widget.from].instructions
              : '';
          _center = addressList[widget.from].latlng;
          _centerLocation = addressList[widget.from].latlng;
          dropAddressConfirmation = addressList[widget.from].address;
        });
      } else if (widget.from != null && widget.from == 'favourite') {
        var loc = await geolocs.Geolocator.getCurrentPosition(
            desiredAccuracy: geolocs.LocationAccuracy.low);
        if (!mounted) return;
        setState(() {
          _center = LatLng(double.parse(loc.latitude.toString()),
              double.parse(loc.longitude.toString()));
          _centerLocation = LatLng(double.parse(loc.latitude.toString()),
              double.parse(loc.longitude.toString()));
        });
      } else if (widget.from == 'add stop') {
        if (locs != null) {
          setState(() {
            _center = LatLng(double.parse(locs.latitude.toString()),
                double.parse(locs.longitude.toString()));
            _centerLocation = LatLng(double.parse(locs.latitude.toString()),
                double.parse(locs.longitude.toString()));
          });
        } else {
          var loc = await geolocs.Geolocator.getCurrentPosition(
              desiredAccuracy: geolocs.LocationAccuracy.low);
          if (!mounted) return;
          setState(() {
            _center = LatLng(double.parse(loc.latitude.toString()),
                double.parse(loc.longitude.toString()));
            _centerLocation = LatLng(double.parse(loc.latitude.toString()),
                double.parse(loc.longitude.toString()));
          });
        }
        setState(() {
          _center = addressList.firstWhere((e) => e.type == 'pickup').latlng;
          _centerLocation =
              addressList.firstWhere((e) => e.type == 'pickup').latlng;
          dropAddressConfirmation = addressList
              .firstWhere((element) => element.type == 'pickup')
              .address;

          useMyAddress = true;
        });
      } else {
        setState(() {
          _center = addressList.firstWhere((e) => e.type == 'drop').latlng;
          _centerLocation =
              addressList.firstWhere((e) => e.type == 'drop').latlng;
          if (addressList.length >= 2) {
            dropAddressConfirmation = addressList
                .firstWhere((element) => element.type == 'drop')
                .address;
          }
          useMyAddress = true;
        });
      }

      setState(() {
        _state = '3';
        _isLoading = false;
      });
    }
  }

  navigateLogout() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false);
  }

  popFunction() {
    if (_getDropDetails == true) {
      return false;
    } else {
      addressList.removeWhere((element) => element.id == 'drop');
      return true;
    }
  }
}
