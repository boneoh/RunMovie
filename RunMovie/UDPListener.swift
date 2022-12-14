    //
    //  UDPListener.swift
    //
    //  Created by Michael Robert Ellis on 12/16/21.
    //

    // pma 12/12/2022  many changes

    import Foundation
    import Network
    import Combine

    class UDPListener: ObservableObject {
        
        var listener: NWListener?
        var connection: NWConnection?
        var queue = DispatchQueue.global(qos: .userInitiated)
        /// New data will be place in this variable to be received by observers
        @Published private(set) public var messageReceived: Data?
        /// When there is an active listening NWConnection this will be `true`
        @Published private(set) public var isReady: Bool = false
        /// Default value `true`, this will become false if the UDPListener ceases listening for any reason
        @Published public var listening: Bool = true
        
        /// A convenience init using Int instead of NWEndpoint.Port
        convenience init(on port: Int) {
            self.init(on: NWEndpoint.Port(integerLiteral: NWEndpoint.Port.IntegerLiteralType(port)))
        }
        /// Use this init or the one that takes an Int to start the listener
        init(on port: NWEndpoint.Port) {
            let params = NWParameters.udp
            params.allowFastOpen = true
            
            params.allowLocalEndpointReuse = true
            
            print("UDPListener init - creating NWListener port \(port)")
            
            self.listener = try? NWListener(using: params, on: port)
                       
            self.listener?.stateUpdateHandler = { update in
                switch update {
                case .ready:
                    self.isReady = true
                    print("Listener connected to port \(port)")
                        
                case .failed, .cancelled:
                    // Announce we are no longer able to listen
                    self.listening = false
                    self.isReady = false
                    print("Listener disconnected from port \(port)")    // $$$
                default:
                    print("Listener connecting to port \(port)...")
                }
            }
            self.listener?.newConnectionHandler = { connection in
                print("Listener creating connection")
                self.createConnection(connection: connection)
            }
            self.listener?.start(queue: self.queue)
        }
        
        func createConnection(connection: NWConnection) {
            print("Listener createConnection was invoked - \(connection)")
            self.connection = connection
            self.connection?.stateUpdateHandler = { (newState) in
                switch (newState) {
                case .ready:
                    print("Listener ready to receive message - \(connection)")
                    // self.receive()
                case .cancelled, .failed:
                    print("Listener failed to receive message - \(connection)")
                    // Cancel the listener, something went wrong
                    self.listener?.cancel()
                    // Announce we are no longer able to listen
                    self.listening = false
                default:
                    print("Listener waiting to receive message - \(connection)")
                }
            }
            
            self.receive()
            
            self.connection?.start(queue: .global())
        }
        
        func receive() {
            self.connection?.receiveMessage { data, context, isComplete, error in
                if let unwrappedError = error {
                    print("Error: NWError received in \(#function) - \(unwrappedError)")
                    return
                }
                guard isComplete, let data = data else {
                    print("Error: Received nil Data with context - \(String(describing: context))")
                    return
                }
                
                print("Listener received message")
                
                self.messageReceived = data
                
                let str = String(decoding: data, as: UTF8.self)
                
                print("Listener received message - \(str)")
                
                if self.listening {
                    print("Listener invoking self.receive")
                    self.receive()
                }
                else
                {
                    print("Listener is no longer listening")
                }
            }
        }
        
        func cancel() {
            self.listening = false
            self.connection?.cancel()
        }
    }
