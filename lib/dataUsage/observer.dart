// abstract class Observer {
//   void update(Observable observable, Object arg);
// }

// class Observable {
//   final List<Observer> _observers = [];

//   bool addObserver(Observer observer) {
//     if (_observers.contains(observer)) {
//       return false;
//     }
//     _observers.add(observer);
//     return true;
//   }

//   bool removeObserver(Observer observer) {
//     return _observers.remove(observer);
//   }

//   void notifyObservers(Object arg) {
//     for (var observer in _observers) {
//       observer.update(this, arg);
//     }
//   }
// }
