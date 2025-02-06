import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:taxista/features/splash/data/datasource/onboarding_pages.dart';
part 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit() : super(const OnboardingState(0));
  PageController pageController = PageController();

  void _changePage(int index) {
    emit(state.copyWith(index: index));
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  bool increment(BuildContext context) {
    int newIndex = state.index + 1;
    if (newIndex > OnboardingPages.getPages(context).length - 1) return false;
    _changePage(newIndex);
    return true;
  }

  bool decrement() {
    int newIndex = state.index - 1;
    if (newIndex < 0) return false;
    _changePage(newIndex);
    return true;
  }

  void skip(BuildContext context) {
    int newIndex = OnboardingPages.getPages(context).length - 1;
    emit(state.copyWith(index: newIndex));
    pageController.jumpToPage(
      newIndex,
    );
  }

  void changeIndex(int index) {
    emit(state.copyWith(index: index));
  }
}
