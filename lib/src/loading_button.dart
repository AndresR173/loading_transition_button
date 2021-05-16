import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v;

class LoadingButton extends StatefulWidget {
  /// Background color of the button for the default / steady state.  If not set
  /// this will default to the accent color of the current [Theme].
  final Color? color;

  /// Controller to be able to notify when the button can
  /// move to the next page o should animate to an
  /// errored state
  final LoadingButtonController controller;

  /// Duration for the button animation.
  final Duration duration;

  /// Duration for the page trnasition
  final Duration transitionDuration;

  /// Background color for error state
  /// if null, it will use [color] by default
  final Color? errorColor;

  /// Use this callback to listen for interactions
  /// with the loading button
  final VoidCallback? onSubmit;

  /// The child widget for the loading button
  final Widget child;

  /// A button that respresents a loading and errored stated
  /// if given a [LoadingButtonController], this widget can use the [moveToScreen]
  /// to animate a transition to a new page
  LoadingButton({
    Key? key,
    this.color,
    this.duration = const Duration(milliseconds: 300),
    this.transitionDuration = const Duration(milliseconds: 400),
    this.onSubmit,
    required this.controller,
    required this.child,
    this.errorColor,
  })  : assert(duration.inMilliseconds > 0),
        super(key: key);

  @override
  _LoadginButtonState createState() => _LoadginButtonState();
}

class _LoadginButtonState extends State<LoadingButton>
    with TickerProviderStateMixin, RouteAware {
  late AnimationController _controller;

  /// if null, it will use the accent color by default
  Color? _buttonColor;
  bool _isLoading = false;
  bool _isError = false;
  bool _isReversed = false;
  double _parentHeight = 0;

  // Transition
  GlobalKey _buttonKey = GlobalKey();

  final RouteObserver<PageRoute<dynamic>> routeObserver =
      RouteObserver<PageRoute>();

  @override
  void initState() {
    widget.controller._state = this;

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..addListener(() => setState(() {}));

    super.initState();
  }

  @override
  didPopNext() {
    setState(() => _isLoading = false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _buttonColor = widget.color ?? Theme.of(context).accentColor;
    routeObserver.subscribe(this, ModalRoute.of(context) as PageRoute<dynamic>);

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
    _controller.dispose();
    routeObserver.unsubscribe(this);

    super.dispose();
  }

  // Shake animation
  v.Vector3 _getTranslation() {
    var progress = _controller.value;
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
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            )
          : widget.child,
    );
  }

  double _getBeginWidth(BoxConstraints constraints) {
    if (_isReversed) {
      return _parentHeight;
    }
    return constraints.maxWidth;
  }

  double _getEndWidth(BoxConstraints constraints) {
    if (_isLoading) {
      return _parentHeight;
    }
    return constraints.maxWidth;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      _parentHeight = constraints.maxHeight;
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
          builder: (BuildContext context, double size, Widget? child) {
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

  /// Calls [onSubmit] callback and inits the animation
  void _submitAndAnimate() {
    widget.onSubmit?.call();
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

    final rect = Rect.fromCenter(
        center: fabOffset, width: buttonSize.width, height: buttonSize.height);
    final finalRect = rect.inflate(MediaQuery.of(context).size.longestSide);

    final radiusTween = BorderRadiusTween(
      begin: BorderRadius.circular(buttonSize.height / 2),
      end: BorderRadius.circular(finalRect.size.height / 2),
    );

    final sizeTween = SizeTween(
      begin: buttonSize,
      end: finalRect.size,
    );

    final offsetTween = Tween<Offset>(
        begin: fabOffset,
        end: Offset(MediaQuery.of(context).size.width - finalRect.right,
            MediaQuery.of(context).size.height - finalRect.bottom));

    final easeInAnimation = CurvedAnimation(
      parent: animation,
      curve: Curves.linear,
    );

    final radius = radiusTween.evaluate(easeInAnimation);
    final offset = offsetTween.evaluate(animation);
    final size = sizeTween.evaluate(easeInAnimation);

    Widget positionedClippedChild(Widget child) => Positioned(
          width: size!.width,
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
        positionedClippedChild(Container(color: _buttonColor)),
      ],
    );
  }

  _moveToNextPage({
    required BuildContext context,
    required Widget page,
    bool stopAnimation = false,
    required NavigationCallback callback,
  }) {
    final RenderBox buttonRenderBox =
        _buttonKey.currentContext!.findRenderObject() as RenderBox;
    final buttonSize = buttonRenderBox.size;
    final buttonOffset = buttonRenderBox.localToGlobal(Offset.zero);

    final pageBuilder = PageRouteBuilder(
      transitionDuration: widget.transitionDuration,
      pageBuilder: (BuildContext context, Animation<double> animation,
              Animation<double> secondaryAnimation) =>
          page,
      transitionsBuilder: (BuildContext context, Animation<double> animation,
              Animation<double> secondaryAnimation, Widget child) =>
          _buildTransition(context, child, animation, buttonSize, buttonOffset),
    );

    callback(pageBuilder);

    if (stopAnimation) _stopAnimation();
  }
}

typedef NavigationCallback = Function(PageRouteBuilder);

/// This controller defines a set of helper methods
/// that notifies the loading button about the state of the
/// animation
class LoadingButtonController {
  late _LoadginButtonState _state;

  /// Stops the loading animation and init the error state
  void onError() {
    _state._isError = true;
    _state._stopAnimation();
  }

  /// Inits the loading state and fires [onSubmit] callback
  /// When the loading animation is running, the button will
  /// be disabled
  void startLoadingAnimation() {
    _state._iniAnimation();
  }

  /// Stops loading animations
  void stopLoadingAnimation() {
    _state._stopAnimation();
  }

  /// Inits the transition to the next page
  /// Please provide the next [page] that you want to present to the user.
  /// If you want to stop the button animation once the [page] is presented,
  /// you can set [stopAnimation] as true.
  /// Finally, provide a [navigationCallback] that will let you set the navigation
  /// behavior, this callback will return the new route.
  void moveToScreen({
    required BuildContext context,
    required Widget page,
    required stopAnimation,
    required NavigationCallback navigationCallback,
  }) {
    _state._moveToNextPage(
      context: context,
      page: page,
      stopAnimation: stopAnimation,
      callback: navigationCallback,
    );
  }
}
