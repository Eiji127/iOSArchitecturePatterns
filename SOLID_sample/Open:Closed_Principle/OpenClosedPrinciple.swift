
/*
 Open/Closed Principle(= 開放閉鎖の原則)でしたいこと
 ・変わりやすい部分、変わらない部分を分離(
 1. TextMessageとImageMessageの変わる部分を閉じ込め、送信処理部分は共通化する。
 )
 */

protocol MessageSenderAPIProtocol {
    func fetchAll(ofUserId: Int, completion: ...)
    func fetch(id: Int, completion: ...)
    func sendTextMessage(text: String, completion: ...)
    func sendImageMessage(image: UIImage, text: String?, completion: ...)
}

final class CommonMessageAPI: CommonMessageAPIProtocol {
    func fetchAll(ofUserId: Int, completion: @escaping ([Message]?) -> Void) { ... }
    func fetch(id: Int, completion: @escaping (Message?) -> Void) { ... }
    func sendTextMessage(text: String, completion: @escaping (TextMessage?) -> Void) { ... }
    func sendImageMessage(image: UIImage, text: String?, completion: @escaping (ImageMessage?) -> Void) { ... }
}

// ↓ SendableMessageStarategyのcaseが増えてもMessageSenderを変更する必要はない（SendableMessageStrategy は「拡張に対して開い」ており、 MessageSender は「修正 に対して閉じ」ている）
enum SendableMessageStrategy {
    case text(api: TextMessageSenderAPI, input: TextMessageInput)
    case image(api: ImageMessageSenderAPI, input: ImageMessageInput)
    
    mutating func update(input: Any) {...} // inputを置き換える
    func send(completion: @escaping(Message?) -> Void) {...} // caseごとに通信を行う
}

// 新たなErrorを追加したいときOpen/Closed Principleを適用すると良い
enum State {
    case inputting(validationError: Error?)
    case sending
    case sent(Message)
    case connectionFailed
}

enum ImageMessageInputError: Error {
    case noImage, tooLongText(count: Int)
}

struct ImageMessageInput {
    var text: String?
    var image: UIImage?
    func validate() throws -> (image: UIImage, text: String?) {
        guard let image = image else {
            throw ImageMessageInputError.noImage
        }
        if let text = text, text.count >= 80
        {
            throw ImageMessageInputError.tooLongText(count: text.count)
        }
        return (image, text)
        
    }
}

struct ImageMessageInputValidator {
    let image: UIImage?
    let text: String?
    var isValid: Bool {
        if image == nil { return false }
        if let text = text, text.count > 80 { return false }
        return true
    }
}

struct MessageInputValidator {
    let messageType: MessageType
    let image: UIImage?
    let text: String?
    private var isTextValid: Bool {
        switch messageType {
        case .text: return text != nil && text!.count <= 300 // 300 字以内
        case .image: return text == nil || text!.count <= 80 // 80 字以内 or nil
        case .official: return false // ← これいらん！！
        }
    }
    
    private var isImageValid: Bool {
        return image != nil // imageの場合だけ考慮する
    }
    
    private var isValid: Bool {
        switch messageType {
        case .text: return isTextValid
        case .image: return isTextValid && isImageValid
        case .official: return false // OfficialMessageはありえない
        }
    }
}

final class MessageSender {
    private let api: CommonMessageAPI // ← MessageSender をインスタンス化したときに、CommonMessageAPIProtocol に適合した何者かを渡すようにコードを変更
    let messageType: MessageType
    var delegate: MessageSenderDelegate?
    init(messageType: MessageType, api: CommonMessageAPI) {
        self.messageType = messageType
        self.api = api
    }
    
    
    var text: String? { // TextMessage,ImageMessageどちらの場合も使う
        didSet { if !isTextValid { delegate?.validではないことを伝える() } }
    }
    var image: UIImage? { // ImageMessageの場合に使う
        didSet { if !isImageValid { delegate?.validではないことを伝える() } }
    }
    // 通信結果
    private(set) var isLoading: Bool = false
    private(set) var result: Message? // 送信成功したら値が入る
    
    func send() {
        guard isValid else { delegate?.validではないことを伝える() }
        isLoading = true
        switch messageType {
        case .text:
            api.sendTextMessage(text: text!) { [weak self] in
                self?.isLoading = false
                self?.result = $0
                self?.delegate?. 通信完了を伝える ()
            }
        case .image:
            api.sendImageMessage(image: image!, text: text) { ... }
        case .official:
                fatalError()
        }
    }
}





