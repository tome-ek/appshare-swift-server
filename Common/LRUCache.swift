//
//  LRUCache.swift
//  PhoneStreamer-iOS
//
//  Created by Prywatne on 14.08.21.
//

import Foundation

final class Node<K, V> {
    var next: Node?
    var previous: Node?
    var key: K
    var value: V?
    
    init(key: K, value: V?) {
        self.key = key
        self.value = value
    }
}

final class LinkedList<K, V> {
    var head: Node<K, V>?
    var tail: Node<K, V>?
    
    func addToHead(node: Node<K, V>) {
        if self.head == nil  {
            self.head = node
            self.tail = node
        } else {
            let temp = self.head
            
            self.head?.previous = node
            self.head = node
            self.head?.next = temp
        }
    }
    
    func remove(node: Node<K, V>) {
        if node === self.head {
            if self.head?.next != nil {
                self.head = self.head?.next
                self.head?.previous = nil
            } else {
                self.head = nil
                self.tail = nil
            }
        } else if node.next != nil {
            node.previous?.next = node.next
            node.next?.previous = node.previous
        } else {
            node.previous?.next = nil
            self.tail = node.previous
        }
    }
}

final class LRUCache<K: Hashable, V> {
    private let capacity: Int
    private var length = 0
    
    private let queue: LinkedList<K, V>
    private var hashTable: [K : Node<K, V>]
  
    init(capacity: Int) {
        self.capacity = capacity
        
        self.queue = LinkedList()
        self.hashTable = [K : Node<K, V>](minimumCapacity: self.capacity)
    }
    
    subscript (key: K) -> V? {
        get {
            if let node = self.hashTable[key] {
                self.queue.remove(node: node)
                self.queue.addToHead(node: node)
                
                return node.value
            } else {
                return nil
            }
        }
        
        set(value) {
            if let node = self.hashTable[key] {
                node.value = value
                
                self.queue.remove(node: node)
                self.queue.addToHead(node: node)
            } else {
                let node = Node(key: key, value: value)
                
                if self.length < capacity {
                    self.queue.addToHead(node: node)
                    self.hashTable[key] = node
                    
                    self.length = self.length + 1
                } else {
                    hashTable.removeValue(forKey: self.queue.tail!.key)
                    self.queue.tail = self.queue.tail?.previous
                    
                    if let node = self.queue.tail {
                        node.next = nil
                    }
                    
                    self.queue.addToHead(node: node)
                    self.hashTable[key] = node
                }
            }
        }
    }
}
