
/*
 Interface Segregation Principle(= インターフェース分離の法則)でしたいこと
 ・ユーザの送信には関係がない要素を分離(
 1. MessageSenderAPIProtocol内のメソッドfetchAll()とfetch()はメッセージ送信とは関係ない
 2. MessageTypeの.officialのcaseは本来メッセージの送信には関係がない
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

// 「送信できるメッセージ」を網羅している↓
enum SendableMessageType {
    case text, image
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





