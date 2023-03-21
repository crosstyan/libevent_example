cmake_minimum_required(VERSION 3.11)
project(event_test)
add_executable(event_test main.cpp)
target_link_libraries(event_test PRIVATE event_core)
