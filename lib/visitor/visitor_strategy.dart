import 'package:flagship/visitor/Ivisitor.dart';

import '../visitor.dart';

abstract class VisitorStrategy implements IVisitor {
  final Visitor visitor;

  VisitorStrategy(this.visitor);
}
