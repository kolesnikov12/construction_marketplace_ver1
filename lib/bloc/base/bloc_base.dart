import 'dart:async';
import 'bloc_events.dart';
import 'bloc_states.dart';

abstract class Bloc {
  final StreamController<BlocEvent> _eventController = StreamController<BlocEvent>();
  final StreamController<BlocState> _stateController = StreamController<BlocState>.broadcast();

  Stream<BlocState> get state => _stateController.stream;
  StreamSink<BlocState> get _stateSink => _stateController.sink;

  Bloc() {
    _eventController.stream.listen(handleEvent);
    _stateSink.add(InitialState());
  }

  void dispose() {
    _eventController.close();
    _stateController.close();
  }

  void addEvent(BlocEvent event) {
    if (!_eventController.isClosed) {
      _eventController.sink.add(event);
    }
  }

  void emitState(BlocState state) {
    if (!_stateController.isClosed) {
      _stateSink.add(state);
    }
  }

  Future<void> handleEvent(BlocEvent event);
}
