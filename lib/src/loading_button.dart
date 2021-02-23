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

  final Color errorColor;

  final VoidCallback onSubmit;

  final Widget child;

  final double minWidth;

  LoadingButton({
    Key key,
    this.color,
    // this.controller,
    this.duration = const Duration(milliseconds: 300),
    this.onSubmit,
    this.controller,
    this.child,
    this.errorColor,
    this.minWidth,
  })  : assert(duration != null),
        assert(duration.inMilliseconds > 0),
        assert(child != null),
        assert(minWidth != null),
        super(key: key);

  @override
  _LoadginButtonState createState() => _LoadginButtonState();
}

class _LoadginButtonState extends State<LoadingButton>
    with TickerProviderStateMixin, RouteAware {
  final Key _keyLoading = UniqueKey();

  AnimationController _controller;
  Color _buttonColor;
  bool _isLoading = false;
  bool _isError = false;
  bool _isReversed = false;

  // Transition
  GlobalKey _buttonKey = GlobalKey();

  final routeObserver = RouteObserver<PageRoute>();
  final duration = const Duration(milliseconds: 300);

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
    routeObserver.subscribe(this, ModalRoute.of(context));

    Animation startColor = ColorTween(
      begin: widget.color,
      end: widget.errorColor ?? widget.color,
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
      begin: widget.errorColor ?? widget.color,
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
    routeObserver.unsubscribe(this);

    super.dispose();
  }

  @override
  didPopNext() {
    setState(() => _isLoading = true);
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

  double _getBeginWidth(BoxConstraints constraints) {
    if (_isReversed) {
      return widget.minWidth;
    }
    return constraints.maxWidth;
  }

  double _getEndWidth(BoxConstraints constraints) {
    if (_isLoading) {
      return widget.minWidth;
    }
    return constraints.maxWidth;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return Center(
        child: TweenAnimationBuilder(
          curve: Curves.fastOutSlowIn,
          duration: widget.duration,
          tween: Tween<double>(
              begin: _getBeginWidth(constraints),
              end: _getEndWidth(constraints)),
          child: Transform(
            transform: Matrix4.translation(_getTranslation()),
            child: RawMaterialButton(
              key: _buttonKey,
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
          builder: (BuildContext context, double size, Widget child) {
            return Container(
              height: constraints.maxHeight,
              width: size,
              child: child,
            );
          },
          onEnd: () {
            if (_isError) {
              _controller.reset();
              _controller.forward();
              _isError = false;
            }
          },
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
      _isReversed = true;
      _isLoading = false;
    });
  }

  void _iniAnimation() {
    setState(() {
      _isReversed = false;
      _isError = false;
      _isLoading = true;
    });
  }

  Widget _buildTransition(
    BuildContext context,
    Widget page,
    Animation<double> animation,
    Size buttonSize,
    Offset fabOffset,
  ) {
    if (animation.value == 1) return page;

    final radiusTween = BorderRadiusTween(
      begin: BorderRadius.circular(buttonSize.width / 2),
      end: BorderRadius.circular(0),
    );

    final sizeTween = SizeTween(
      begin: buttonSize,
      end: Size(MediaQuery.of(context).size.height,
          MediaQuery.of(context).size.height),
    );

    final offsetTween = Tween<Offset>(begin: fabOffset, end: Offset.zero);

    final easeInAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.easeIn,
    );

    final radius = radiusTween.evaluate(easeInAnimation);
    final offset = offsetTween.evaluate(animation);
    final size = sizeTween.evaluate(easeInAnimation);

    Widget positionedClippedChild(Widget child) => Positioned(
          width: size.width,
          height: size.height,
          left: offset.dx,
          top: offset.dy,
          child: ClipRRect(
            borderRadius: radius,
            child: child,
          ),
        );

    return Stack(
      children: [
        positionedClippedChild(Container(color: widget.color)),
        // positionedClippedChild(transitionFab),
      ],
    );
  }

  _onMoveToNextPage(BuildContext context, Widget page) {
    final RenderBox fabRenderBox = _buttonKey.currentContext.findRenderObject();
    final fabSize = fabRenderBox.size;
    final fabOffset = fabRenderBox.localToGlobal(Offset.zero);

    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: duration,
        pageBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondaryAnimation) =>
            page,
        transitionsBuilder: (BuildContext context, Animation<double> animation,
                Animation<double> secondaryAnimation, Widget child) =>
            _buildTransition(context, child, animation, fabSize, fabOffset),
      ),
    );
  }
}

class LoadingButtonController {
  _LoadginButtonState _state;

  void onError() {
    _state._isError = true;
    _state._stopAnimation();
  }

  void startLoadingAnimation() {
    _state._iniAnimation();
  }

  void stopLoadingAnimation() {
    _state._stopAnimation();
  }

  void moveToScreen({BuildContext context, Widget page}) {
    _state._onMoveToNextPage(context, page);
  }
}
