/// Module: todolist
module todolist::todolist;

use std::string::String;
use sui::event;


// === STRUCTS ===

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
    new_task: String,
}

public struct TodoCompleted has copy, drop {
    list_id: ID,
    todo_id: u64,
    completed: bool,
}

public struct TodoDeleted has copy, drop {
    list_id: ID,
    todo_id: u64
}

// === INITIALIZATION ===
fun init(ctx: &mut TxContext){

    let sender = ctx.sender();

    let list = TodoList {
        id: object::new(ctx),
        todos: vector::empty<Todo>(),
        next_id: 0,
        owner: sender
    };

    transfer::transfer(list, sender);
}

// === CRUD OPERATIONS ===

// Create a new Todo
public fun create_todo(list: &mut TodoList, task: String){
    let id = list.next_id;

    let todo = Todo{
        id: id,
        task: task,
        completed: false
    };

    vector::push_back(&mut list.todos, todo);
    list.next_id = id + 1;

    event::emit(TodoCreated{
        list_id: object::uid_to_inner(&list.id),
        todo_id: id,
        task: task
    });
}

// Update a Todo as completed
public fun update_todo(list: &mut TodoList, todo_id: u64, new_task: String){
    let index = find_todo_by_index(list, todo_id);
    let todo = vector::borrow_mut<Todo>(&mut list.todos, index);
    todo.task = new_task;

    event::emit(TodoUpdated{
        list_id: object::uid_to_inner(&list.id),
        todo_id: todo_id,
        new_task: new_task
    });
}

// Update a Todo as completed
public fun todo_completed(list: &mut TodoList, todo_id: u64, completed: bool){
    let index = find_todo_by_index(list, todo_id);
    let todo = vector::borrow_mut<Todo>(&mut list.todos, index);
    todo.completed = completed;

    event::emit(TodoCompleted{
        list_id: object::uid_to_inner(&list.id),
        todo_id: todo_id,
        completed: completed
    });
}

// Delete a Todo
public fun delete_todo(list: &mut TodoList, todo_id: u64){
    let index = find_todo_by_index(list, todo_id);
    vector::remove(&mut list.todos, index);

    event::emit(TodoDeleted{
        list_id: object::uid_to_inner(&list.id),
        todo_id: todo_id
    });
}

// === VIEW METHODS ===
public fun get_todos(list: &TodoList): &vector<Todo>{
    &list.todos
}

public fun get_todo_by_id(list: &TodoList, todo_id: u64): &Todo{
    let index = find_todo_by_index(list, todo_id);
    vector::borrow<Todo>(&list.todos, index)
}

public fun get_todo_count(list: &TodoList): u64{
    vector::length(&list.todos)
}

// === HELPER FUNCTIONS ===
fun find_todo_by_index(list: &TodoList, todo_id: u64): u64{
    let mut i = 0;

    while(i < vector::length(&list.todos)){
        let todo = vector::borrow<Todo>(&list.todos, i);
        if(todo.id == todo_id){
            return i
        };
        i = i + 1;
    };

    abort 0
}


// ========== TEST SECTION ==========
#[test_only]
use sui::test_scenario;
#[test_only]
use std::string;
use std::unit_test::assert_eq;



#[test]
fun test_todolist_workflow() {
    let owner = @0x0; // Use default test address
    let mut scenario = test_scenario::begin(owner);

    // === Initialization ===
		{
				init(scenario.ctx());
		};
    
    // === Transaction 1: Publish package (auto-inits) ===
    scenario.next_tx(owner);
    {
        // Init happens automatically here
        let list = test_scenario::take_from_sender<TodoList>(&scenario);
        assert!(get_todo_count(&list) == 0, 0);
        assert!(list.next_id == 0, 1);
        test_scenario::return_to_sender(&scenario, list);
    };

    // === Transaction 2: Create Todo ===
    scenario.next_tx(owner);
    {
        let mut list = test_scenario::take_from_sender<TodoList>(&scenario);
        create_todo(&mut list, string::utf8(b"Buy groceries"));
        create_todo(&mut list, string::utf8(b"Learn Move"));

        assert!(get_todo_count(&list) == 2, 2);
        test_scenario::return_to_sender(&scenario, list);
    };

    // === Transaction 3: Update todo ===
    scenario.next_tx(owner);
    {
        let mut list = test_scenario::take_from_sender<TodoList>(&scenario);
        update_todo(&mut list, 1, string::utf8(b"Learn Sui Move"));
        todo_completed(&mut list, 1, true);
        test_scenario::return_to_sender(&scenario, list);
    };

    // === Transaction 4: Verify state ===
    scenario.next_tx(owner);
    {
        let list = test_scenario::take_from_sender<TodoList>(&scenario);
        let todo = get_todo_by_id(&list, 1);
        assert_eq!(todo.task, string::utf8(b"Learn Sui Move"));
        assert!(todo.completed);
        test_scenario::return_to_sender(&scenario, list);
    };

    // === Transaction 5: Delete todo ===
    scenario.next_tx(owner);
    {
        let mut list = test_scenario::take_from_sender<TodoList>(&scenario);
        delete_todo(&mut list, 0);
        assert_eq!(get_todo_count(&list), 1);
        test_scenario::return_to_sender(&scenario, list);
    };

    scenario.end();
}

#[test]
fun test_event_emissions(){
    let owner = @0xBEEF;
    let mut scenario = test_scenario::begin(owner);

    // === Transaction 1: Initialize TodoList ===
    scenario.next_tx(owner);
    {
        let ctx = test_scenario::ctx(&mut scenario);
        init(ctx);
    };

    // === Transaction 2: Create Todo ===
    let effects = test_scenario::next_tx(&mut scenario, owner);
    {
        let mut list = test_scenario::take_from_sender<TodoList>(&scenario);
        create_todo(&mut list, string::utf8(b"Build on Sui"));
        test_scenario::return_to_sender(&scenario, list);
    };
    assert_eq!(test_scenario::num_user_events(&effects), 0);

    // === Transaction 3: Update Todo ===
    let effects2 = test_scenario::next_tx(&mut scenario, owner);
    {
        let mut list = test_scenario::take_from_sender<TodoList>(&scenario);
        update_todo(&mut list, 0, string::utf8(b"Build on Sui Blockchain"));
        test_scenario::return_to_sender(&scenario, list);
    };
    assert_eq!(test_scenario::num_user_events(&effects2), 1);

    test_scenario::end(scenario);
}

#[test]
#[expected_failure(abort_code = 0, location = todolist::todolist)]
fun test_invalid_todo_id(){
    let owner = @0x0;
    let mut scenario = test_scenario::begin(owner);

    // Initialize
    scenario.next_tx(owner);
    let ctx = test_scenario::ctx(&mut scenario);
    init(ctx);

    // Take list
    scenario.next_tx(owner);
    let mut list = test_scenario::take_from_sender<TodoList>(&scenario);
    
    // Attempt invalid operation
    scenario.next_tx(owner);
    {
        update_todo(&mut list, 999, string::utf8(b"Should fail"));
        test_scenario::return_to_sender(&scenario, list);
    };

    scenario.end();
}

#[test]
#[expected_failure(abort_code = 3, location = sui::test_scenario)]
fun test_unauthorized_access(){
    let owner = @0xADAC;
    let attacker = @0xDEDE;

    let mut scenario = test_scenario::begin(owner);

    // Owner initializes
    scenario.next_tx(owner);
    {
        let ctx = test_scenario::ctx(&mut scenario);
        init(ctx);
    };


    // Create Todo
    scenario.next_tx(owner);
    {
        let mut list = test_scenario::take_from_sender<TodoList>(&scenario);
        create_todo(&mut list, string::utf8(b"Learn Move"));
        test_scenario::return_to_sender(&scenario, list);
    };

    // Attacker tries to access (should fail)
    scenario.next_tx(attacker);
    {
        // This line will abort with EEmptyInventory (code 3)
        let list = test_scenario::take_from_sender<TodoList>(&scenario);
        test_scenario::return_to_sender(&scenario, list);
    };

    scenario.end();
}

#[test]
fun test_id_sequence() {
    let owner = @0xDEAD;
    let mut scenario = test_scenario::begin(owner);
    
    scenario.next_tx(owner);
    let ctx = test_scenario::ctx(&mut scenario);
    init(ctx);
    
    scenario.next_tx(owner);
    let mut list = test_scenario::take_from_sender<TodoList>(&scenario);
    
    // Create 3 todos
    scenario.next_tx(owner);
    {
        create_todo(&mut list, string::utf8(b"First"));
        create_todo(&mut list, string::utf8(b"Second"));
        create_todo(&mut list, string::utf8(b"Third"));
        test_scenario::return_to_sender(&scenario, list);
    };
    
    // Verify IDs
    scenario.next_tx(owner);
    {
        let list = test_scenario::take_from_sender<TodoList>(&scenario);
        assert_eq!(list.next_id, 3);
        let todo = get_todo_by_id(&list, 2);
        assert_eq!(todo.id, 2);
        test_scenario::return_to_sender(&scenario, list);
    };
    
    scenario.end();
}

#[test]
fun test_delete_all_todos() {
    let owner = @0xCEAD;
    let mut scenario = test_scenario::begin(owner);
    
    scenario.next_tx(owner);
    let ctx = test_scenario::ctx(&mut scenario);
    init(ctx);
    
    scenario.next_tx(owner);
    let mut list = test_scenario::take_from_sender<TodoList>(&scenario);
    
    // Add todos
    scenario.next_tx(owner);
    {
        create_todo(&mut list, string::utf8(b"Temp 1"));
        create_todo(&mut list, string::utf8(b"Temp 2"));
        test_scenario::return_to_sender(&scenario, list);
    };
    
    // Delete todos
    scenario.next_tx(owner);
    {
        let mut list = test_scenario::take_from_sender<TodoList>(&scenario);
        delete_todo(&mut list, 0);
        delete_todo(&mut list, 1);
        assert_eq!(get_todo_count(&list), 0);
        test_scenario::return_to_sender(&scenario, list);
    };
    
    scenario.end();
}

#[test]
#[expected_failure(abort_code = 3, location = sui::test_scenario)]
fun test_concurrent_modification() {
    let owner = @0xCADE;
    let mut scenario = test_scenario::begin(owner);
    
    // === Initialization ===
    scenario.next_tx(owner);
    {
        let ctx = test_scenario::ctx(&mut scenario);
        init(ctx);
    };
    
    // === Get TodoList ===
    scenario.next_tx(owner);
    let list = test_scenario::take_from_sender<TodoList>(&scenario);
    
    // === First Modification ===
    scenario.next_tx(owner);
    {
        let mut list = test_scenario::take_from_sender<TodoList>(&scenario);
        create_todo(&mut list, string::utf8(b"Task"));
        test_scenario::return_to_sender(&scenario, list);
    };
    
    // === Concurrent Modification Attempt ===
    scenario.next_tx(owner);
    {
        // This will fail because previous transaction already modified the object
        let mut stale_list = list;
        delete_todo(&mut stale_list, 0);
        test_scenario::return_to_sender(&scenario, stale_list);
    };
    
    scenario.end();
}