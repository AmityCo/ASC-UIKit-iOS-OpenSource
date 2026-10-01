import XCTest
@testable import AmityUIKit4

/// PDT-5958: mention links were `https://www.amity.co/mentionuser/<userId>`. A user id containing `/`
/// broke the interceptor's match, so the tap fell through to Safari and opened amity.co.
final class AmityInternalLinkTests: XCTestCase {

    private let trickyIds = [
        "normalUser",
        "M4ErIcxhpkyFFSp4DJS/vA",
        "1sLIpL9XX0KM/iPjYB5Uww",
        "a?b",
        "a#b",
        "100%",
        "%2F",
        "a+b=",
        "a&b=c",
        "has space",
        "ผู้ใช้",
    ]

    func testLinksUsePrivateScheme() throws {
        let links: [AmityInternalLink] = [.mention(userId: "u/1"), .hashtag("tag"), .productTag(productId: "p/1")]
        for link in links {
            let url = try XCTUnwrap(link.url)
            XCTAssertEqual(url.scheme, AmityInternalLink.scheme)
            XCTAssertTrue(AmityInternalLink.isInternal(url))
        }
    }

    func testIdsRoundTrip() throws {
        for id in trickyIds {
            for link in [AmityInternalLink.mention(userId: id), .hashtag(id), .productTag(productId: id)] {
                let url = try XCTUnwrap(link.url, "\(link)")
                XCTAssertEqual(AmityInternalLink(url: url), link, url.absoluteString)
            }
        }
    }

    func testMentionAllRoundTripsWithEmptyUserId() throws {
        let url = try XCTUnwrap(AmityInternalLink.mention(userId: "").url)
        XCTAssertEqual(AmityInternalLink(url: url), .mention(userId: ""))
    }

    func testWebLinksAreNotInternal() throws {
        for string in ["https://www.amity.co/mentionuser/M4ErIcxhpkyFFSp4DJS/vA", "https://example.com/?userId=1"] {
            let url = try XCTUnwrap(URL(string: string))
            XCTAssertFalse(AmityInternalLink.isInternal(url))
            XCTAssertNil(AmityInternalLink(url: url))
        }
    }
}

final class ChatInternalLinkRouterTests: XCTestCase {

    private final class MentionSpyBehavior: AmityMessageBubbleBehavior {
        var tappedUserIds: [String] = []

        override func onMentionUserTap(context: AmityMessageBubbleBehavior.Context) {
            tappedUserIds.append(context.userId)
        }
    }

    private var originalBehavior: AmityMessageBubbleBehavior?
    private var spy: MentionSpyBehavior!

    override func setUp() {
        super.setUp()
        originalBehavior = AmityUIKit4Manager.behaviour.messageBubbleBehavior
        spy = MentionSpyBehavior()
        AmityUIKit4Manager.behaviour.messageBubbleBehavior = spy
    }

    override func tearDown() {
        AmityUIKit4Manager.behaviour.messageBubbleBehavior = originalBehavior
        super.tearDown()
    }

    func testMentionTapReachesOverrideWithFullUserId() throws {
        let url = try XCTUnwrap(AmityInternalLink.mention(userId: "M4ErIcxhpkyFFSp4DJS/vA").url)
        XCTAssertTrue(ChatInternalLinkRouter.handle(url, sourceViewController: nil))
        XCTAssertEqual(spy.tappedUserIds, ["M4ErIcxhpkyFFSp4DJS/vA"])
    }

    func testMentionAllReachesOverrideWithEmptyUserId() throws {
        let url = try XCTUnwrap(AmityInternalLink.mention(userId: "").url)
        XCTAssertTrue(ChatInternalLinkRouter.handle(url, sourceViewController: nil))
        XCTAssertEqual(spy.tappedUserIds, [""])
    }

    func testHashtagAndProductTagAreConsumedWithoutMentionTap() throws {
        for link in [AmityInternalLink.hashtag("tag"), .productTag(productId: "p/1")] {
            XCTAssertTrue(ChatInternalLinkRouter.handle(try XCTUnwrap(link.url), sourceViewController: nil))
        }
        XCTAssertEqual(spy.tappedUserIds, [])
    }

    func testMalformedInternalLinkIsStillConsumed() throws {
        let url = try XCTUnwrap(URL(string: "amity-uikit://unknown?x=1"))
        XCTAssertTrue(ChatInternalLinkRouter.handle(url, sourceViewController: nil))
        XCTAssertEqual(spy.tappedUserIds, [])
    }

    func testWebLinkIsLeftForTheBrowser() throws {
        let url = try XCTUnwrap(URL(string: "https://www.amity.co/mentionuser/M4ErIcxhpkyFFSp4DJS/vA"))
        XCTAssertFalse(ChatInternalLinkRouter.handle(url, sourceViewController: nil))
        XCTAssertEqual(spy.tappedUserIds, [])
    }
}
