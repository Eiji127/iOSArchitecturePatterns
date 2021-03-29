
// MessageSenderクラス内でCommonMessageAPIProtocolをConstructor Injectionを利用して導入したことにより、特定の目的に沿ったスタブを量産し、各テストケースで意図的に挙動を変えられるようになった。
struct Stub必ず成功するTextMessageAPI: CommonMessageAPIProtocol {
    ...
    func sendTextMessage(text: String, completion: ...) { DispatchQueue.main.async {
            completion(ImageMessage(id: 1, image: ..., text: "成功したよ"))
        }
    }
    ...
}

struct Stub必ず失敗するTextMessageAPI: CommonMessageAPIProtocol {
    ...
}
