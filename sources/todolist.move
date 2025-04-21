/// Module: todolist
module todolist::todolist;

use std::string::String;
use sui::event;

// Struct for Todo
public struct Todo has store, copy, drop{
    id: u64,
    task: String,
    completed: bool,
}

// Struct for TodoList
public struct TodoList has key, store {
    id: UID,
    todos: vector<Todo>,
    next_id: u64,
    owner: address,
}

// === EVENTS ===
public struct TodoCreated has copy, drop {
    list_id: ID,
    todo_id: u64,
    task: String,
}

public struct TodoUpdated has copy, drop {
    list_id: ID,
    todo_id: u64,
    completed: bool,
}