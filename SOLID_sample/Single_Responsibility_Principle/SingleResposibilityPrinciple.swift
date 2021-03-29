final class CommonMessageAPI {
    func fetchAll(ofUserId: Int, completion: @escaping ([Message]?) -> Void) { ... }
    func fetch(id: Int, completion: @escaping (Message?) -> Void) { ... }
    func sendTextMessage(text: String, completion: @escaping (TextMessage?) -> Void) { ... }
    func sendImageMessage(image: UIImage, text: String?, completion: @escaping (ImageMessage?) -> Void) { ... }
}

// ImageMessageの入力値に関するプロパティはimageとtextの２つだとわかる↓
struct ImageMessageInputValidator {
    let image: UIImage?
    let text: String?
    var isValid: Bool {
        if image == nil { return false }
        if let text = text, text.count > 80 { return false }
        return true
    }
}

// validationのみを責務とする型 → MessageSender の isLoading や result といった状態のことは気にする必要はない
struct MessageInputValidator {
    let messageType: MessageType
    let image: UIImage?
    let text: String?
    private var isTextValid: Bool {
        switch messageType { // ← ここでswitchする必要がない(TextMessageとImageMessageは本来関連のない処理のはず)
        case .text: return text != nil && text!.count <= 300 // 300 字以内
        case .image: return text == nil || text!.count <= 80 // 80 字以内 or nil
        case .official: return false // OfficialMessageはありえない
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
    private let api = CommonMessageAPI()
    let messageType: MessageType
    var delegate: MessageSenderDelegate?
    // MessageType.officialをセットするのは禁止!!
    init(messageType: MessageType) {
        self.messageType = messageType
    }// 送信するメッセージの入力値
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




