import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v;

class LoadingButton extends StatefulWidget {
  /// Background color of the FAB for the default / steady state.  If not set
  /// this will default to the accent color of the current [Theme].
  final Color color;

  /// Optional controller to be able to listen for error state events as well as
  /// firing pressed and error events directly.
  final LoadingButtonController controller;

  /// Duration for the error transition.
  final Duration duration;

  /// Background color of the FAB when in an error state.
  final Color loadingColor;

  final Color errorColor;

  /// Icon to display when the FAB is in the default / steady state.
  final IconData icon;

  final VoidCallback onSubmit;

  final Widget child;

  LoadingButton({
    Key key,
    this.color,
    // this.controller,
    this.duration = const Duration(milliseconds: 300),
    this.icon = Icons.arrow_forward,
    this.onSubmit,
    this.controller,
    this.loadingColor,
    this.child,
    this.errorColor = Colors.red,
  })  : assert(duration != null),
        assert(duration.inMilliseconds > 0),
        assert(icon != null),
        assert(child != null),
        super(key: key);

  @override
  _LoadginButtonState createState() => _LoadginButtonState();
}

class _LoadginButtonState extends State<LoadingButton>
    with TickerProviderStateMixin {
  final Key _keyLoading = UniqueKey();

  AnimationController _controller;
  Color _buttonColor;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    widget.controller?._state = this;

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addListener(() => setState(() {}));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _buttonColor = widget.color ?? Theme.of(context).accentColor;

    Animation startColor = ColorTween(
      begin: widget.color,
      end: widget.errorColor,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.2),
      ),
    );
    startColor.addListener(() {
      _buttonColor = startColor.value;
    });

    Animation endColor = ColorTween(
      begin: widget.errorColor,
      end: widget.color,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.8, 1.0),
      ),
    );
    endColor.addListener(() {
      _buttonColor = endColor.value;
    });
  }

  @override
  void dispose() {
    _controller?.dispose();

    super.dispose();
  }

  v.Vector3 _getTranslation() {
    var progress = _controller?.value ?? 0;
    var offset = sin(progress * pi * 5);

    offset *= 12;
    return v.Vector3(offset, 0.0, 0.0);
  }

  Widget _getChildWidget(BuildContext context) {
    return AnimatedSwitcher(
      switchOutCurve: Curves.easeInOutCubic,
      duration: widget.duration,
      child: _isLoading
          ? CircularProgressIndicator(
              key: _keyLoading,
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            )
          : widget.child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return Center(
        child: AnimatedContainer(
          curve: Curves.fastOutSlowIn,
          duration: widget.duration,
          width: _isLoading ? constraints.maxHeight : constraints.maxWidth,
          height: constraints.maxHeight,
          child: Transform(
            transform: Matrix4.translation(_getTranslation()),
            child: RawMaterialButton(
              onPressed: () => (_isLoading || widget.onSubmit == null)
                  ? null
                  : _submitAndAnimate(),
              fillColor: _buttonColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(constraints.maxHeight / 2),
              ),
              child: _getChildWidget(context),
            ),
          ),
        ),
      );
    });
  }

  void _submitAndAnimate() {
    widget.onSubmit();
    _iniAnimation();
  }

  void _stopAnimation() {
    setState(() {
      _isLoading = false;
    });
  }

  void _iniAnimation() {
    setState(() {
      _isLoading = true;
    });
  }
}

class LoadingButtonController {
  _LoadginButtonState _state;

  void onError() {
    _state._stopAnimation();
    _state._controller.reset();
    _state._controller.forward();
  }

  void startLoadingAnimation() {
    _state._iniAnimation();
  }

  void stopLoadingAnimation() {
    _state._stopAnimation();
  }
}
