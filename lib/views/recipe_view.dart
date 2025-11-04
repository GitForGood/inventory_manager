import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:inventory_manager/bloc/recipes/recipes_barrel.dart';
import 'package:inventory_manager/widgets/assist_chip.dart';
import '../models/recipe.dart';

class RecipeView extends StatelessWidget{
  final Recipe recipe;

  const RecipeView({super.key, required this.recipe});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title),
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.arrow_back)),
        actions: [
          BlocBuilder<RecipesBloc, RecipesState>(
            builder: (context, state){
              final favorite = (state is RecipesLoaded)
                ? (state).favorites.contains(recipe)
                : false;
              return IconButton(
                onPressed: (){
                    context.read<RecipesBloc>()
                    .add(ToggleFavorite(recipe));
                }, 
                icon: Icon(favorite 
                ? Icons.favorite 
                : Icons.favorite_border, 
                color: favorite 
                ? Theme.of(context).colorScheme.primary
                : null
                ),
              );
            }
          )
        ],
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AssistChip(icon: Icons.people,labelText: '${recipe.servings} servings'),
              AssistChip(icon: Icons.timer,labelText: '${recipe.readyInMinutes} min'),
              AssistChip(icon: Icons.restaurant,labelText: '${recipe.ingredients.length} ingredients'),
            ]
          ),
          SizedBox(height: 8,),
          Text("Summary", style: Theme.of(context).textTheme.titleLarge),
          Text(recipe.summary ?? "", style: Theme.of(context).textTheme.bodyLarge,),
          SizedBox(height: 8,),
          Text("Ingredients", style: Theme.of(context).textTheme.titleLarge,),
          ...recipe.ingredients.map((e) {
            return Text(
              '${e.amount.round()} ${e.unit?.name} ${e.ingredient?.name}',
              style: Theme.of(context).textTheme.bodyLarge,
            );
          }), 
          SizedBox(height: 8,),
          _RecipeStepList(steps: recipe.instructions),
        ],
      ),
    );
  }
}

class _RecipeStepList extends StatefulWidget{
  final List<String> steps;

  const _RecipeStepList({required this.steps});

  @override
  State<StatefulWidget> createState() => _RecipeListState();
  
}

class _RecipeListState extends State<_RecipeStepList>{
  late List<bool> completed;

  @override
  void initState(){
    super.initState();
    completed = List<bool>.filled(widget.steps.length, false);
  }

  void toggleStep(int index){
    setState(() {
      completed[index] = !completed[index];
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        ListTile(
          title: Text("Steps", style: Theme.of(context).textTheme.titleLarge,),
        ),

        ...widget.steps.asMap().entries.map((MapEntry<int,String> entry){
        return ListTile(
          leading: Checkbox(
            value: completed[entry.key], 
            onChanged: (value) {toggleStep(entry.key);}
          ),
          title: Text(
            '${entry.key}: ${entry.value}', 
            style: completed[entry.key] 
            ? Theme.of(context).textTheme.bodyMedium?.copyWith(decoration: TextDecoration.lineThrough)
            : Theme.of(context).textTheme.bodyMedium
          ),
        );
        }
      )
      ]
    );
  }
}

