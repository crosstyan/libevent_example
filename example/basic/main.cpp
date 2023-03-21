#include <event2/event.h>
#include <event2/util.h>
#include <iostream>
#include <string>
#include <memory>

struct SomeThing {
  event* ev;
  std::unique_ptr<std::string> content;
  int *counter;
};

namespace ev {
  // https://stackoverflow.com/questions/15542530/template-argument-deduction-substitution-failed-when-using-stdfunction-and-st
  /// Have to provide type manually
  ///
  /// https://en.cppreference.com/w/cpp/language/template_argument_deduction
  template<typename T>
  event* event_new(event_base * base, evutil_socket_t fd, short events, void (*callback) (evutil_socket_t, short, T*) , T* args){
    return event_new(base, fd, events, reinterpret_cast<void (*)(evutil_socket_t, short, void*)>(callback), static_cast<void*>(args));
  }
}

int main(void) {
  auto counter = new int;
  auto thing = new SomeThing;
  auto s = std::make_unique<std::string>("Hello World!");
  thing->counter = counter;
  thing->content = std::move(s);
  thing->ev = nullptr;
  auto base = event_base_new();
  auto tv = timeval{1, 0};
  auto say_something = [](int fd, short int events, SomeThing *thing){
    const auto max_called = 5;
    std::cout << "Say: " << *thing->content << "\t" << "counter: " << *thing->counter << "\n";
    *thing->counter += 1;
    if (*thing->counter >= max_called && thing->ev != nullptr){
      event_del(thing->ev);
    }
  };
  // template argument deduction/substitution failed
  auto ev = ev::event_new<SomeThing>(base, -1, EV_PERSIST, say_something, thing);
  thing->ev = ev;
  event_add(ev, &tv);
  event_base_dispatch(base);
  delete thing;
  delete counter;
}
