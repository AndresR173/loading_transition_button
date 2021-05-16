# Loading Transition button

![](https://badges.fyi/github/latest-tag/AndresR173/loading_transition_button)
![](https://badges.fyi/github/stars/AndresR173/loading_transition_button)
![](https://badges.fyi/github/license/AndresR173/loading_transition_button)

A Customizable transition button for Flutter

## Getting Started

To use this package, add `loading_transition_button` as a dependency in your `pubspec.yaml` file.

```yaml
dependencies:
 ...
 loading_transition_button: ^0.0.1
```

## How to use

In your project add the following import:

```dart
import  'package:loading_transition_button/loading_transition_button.dart';
```

In order to use this widget you have to use a `LoadingButtonController` to handler the different states.

```dart
final _controller = LoadingButtonController();
```

This widget starts a loading animation once it's tapped or by using the controller. You can the launcher to
init an error animation or stop the loading animation.

```dart
LoadingButton(
    color: Colors.blue,
    onSubmit: () => print('onSubmit'),
    controller: _controller,
    errorColor: Colors.red,
    transitionDuration: Duration(seconds: 1),
    child: Text(
    'Hit me!',
    style: Theme.of(context)
        .textTheme
        .bodyText1!
        .copyWith(color: Colors.white),
    ),
),
```

To support the transition to a different page to have to call the `moveToScreen` method

```dart
_controller.moveToScreen(
    context: context,
    page: SearchPage(),
    stopAnimation: true,
    navigationCallback: (route) =>
        Navigator.of(context).push(route),
),
```

`navigationCallback` will send you a new route that you can use for different navigation method like push or replace.

# LoadingTransitionButton

![AnimatedButton](https://github.com/AndresR173/loading_transition_button/blob/main/src/animated-button.gif)
