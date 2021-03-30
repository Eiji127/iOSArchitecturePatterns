
/*
 • 単一責任原則によって、複雑なバリデーションを別の型に切り出した
 • 依存関係逆転の原則によって、API 通信の実装を差し替え可能にした
 • インターフェイス分離の原則によって、必要なインターフェイスだけに依存させた
 • 開放閉鎖原則によって、通信状態を enum で、メッセージの種別を generics で扱える
 コードにした
 */



protocol MessageInput {
    associatedtype Payload
    func validate() throws -> Payload
}

protocol MessageSenderAPI {
    associatedtype Payload
    associatedtype Response: Message
    func send(payload: Payload, completion: @escaping (Response?) -> Void)
}

final class MessageSender<API: MessageSenderAPI, Input: MessageInput> where API.Payload == Input.Payload {
    
    enum State {
        case inputting(validationError: Error?) case sending
        case sent(API.Response)
        case connectionFailed
        init(evaluating input: Input) { ... }
        mutating func accept(response: API.Response?) { ... }
    }
    private(set) var state: State {
        didSet { delegate?.stateの変化を伝える() } }
    let api: API
    var input: Input {
        didSet { state = State(evaluating: input) }
    }
    var delegate: MessageSenderDelegate? init(api: API, input: Input) {
        self.api = api
        self.input = input
        self.state = State(evaluating: input)
    }
    func send() {
        do {
            let payload = try input.validate()
            state = .sending
            api.send(payload: payload) { [weak self] in
                self?.state.accept(response: $0)
            }
        } catch let e {
            state = .inputting(validationError: e)
        }
    }
}
