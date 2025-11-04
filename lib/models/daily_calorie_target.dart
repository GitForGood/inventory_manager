abstract class DailyCalorieTarget {
  int get target;

  const DailyCalorieTarget();
}

class ManualCalorieTarget extends DailyCalorieTarget{
  @override
  final int target;

  const ManualCalorieTarget({required this.target});
}

class CalculatedCalorieTarget extends DailyCalorieTarget{
  final int people;
  final int days;
  final int caloriesPerPerson;

  const CalculatedCalorieTarget({required this.people,required this.days,required this.caloriesPerPerson});

  @override
  int get target => (people * days * caloriesPerPerson);
  int get dailyConsumption => (people * caloriesPerPerson);
}