#include <event2/event.h>
#include <event2/util.h>
#include <iostream>
#include <string>
#include <memory>

struct SomeThing {
  std::unique_ptr<std::string> content;
  int *counter;
};

int main(void) {
  auto counter = new int;
  auto thing = new SomeThing;
  auto s = std::make_unique<std::string>("Hello World.");
  thing->counter = counter;
  thing->content = std::move(s);
  auto base = event_base_new();
  auto tv = timeval{1, 0};
  auto say_something = [](int fd, short int events, void *arg){
    auto thing = static_cast<SomeThing*>(arg);
    std::cout << "Say: " << *thing->content << "\t" << "counter: " << *thing->counter << "\n";
    *thing->counter += 1;
  };
  auto ev = event_new(base, -1, EV_PERSIST, say_something, static_cast<void*>(thing));
  event_add(ev, &tv);
  event_base_dispatch(base);
  delete thing;
  delete counter;
}
