//
//  QALocaleVerification.swift
//  AmityUIKit4
//
//  QA helper — call from AppDelegate or a debug menu to apply
//  translated strings and verify localization visually.
//
//  Two approaches demonstrated:
//    1. Thai  → setLocale (replaces ALL strings at once)
//    2. Italian → setOverrides (merges per-key translations)
//
//  Usage:
//    QALocaleVerification.applyThaiLocale()     // Approach 1
//    QALocaleVerification.applyItalianOverrides() // Approach 2
//    QALocaleVerification.resetAll()             // Restore English
//

import Foundation

@MainActor
public enum QALocaleVerification {

    // MARK: - Approach 1: Thai — Full locale bundle (setLocale)
    // This replaces the ENTIRE string table for all three modules.
    // Any key NOT in the bundle falls through to the library default (English).

    public static func applyThaiLocale() {
        AmityStringProvider.social.setLocale("th", bundle: thaiSocialBundle)
        AmityStringProvider.common.setLocale("th", bundle: thaiCommonBundle)
        AmityStringProvider.chat.setLocale("th", bundle: thaiChatBundle)
        print("✅ Thai locale applied via setLocale (Approach 1)")
    }

    // MARK: - Approach 2: Italian — Per-key overrides (setOverrides)
    // Merges translations into existing state. Keys not overridden
    // keep their current value (locale bundle → English default).

    public static func applyItalianOverrides() {
        AmityStringProvider.social.setOverrides(italianSocialOverrides)
        AmityStringProvider.common.setOverrides(italianCommonOverrides)
        AmityStringProvider.chat.setOverrides(italianChatOverrides)
        print("✅ Italian overrides applied via setOverrides (Approach 2)")
    }

    // MARK: - Reset

    public static func resetAll() {
        AmityStringProvider.social.deactivateLocale()
        AmityStringProvider.social.clearOverrides()
        AmityStringProvider.common.deactivateLocale()
        AmityStringProvider.common.clearOverrides()
        AmityStringProvider.chat.deactivateLocale()
        AmityStringProvider.chat.clearOverrides()
        print("✅ All locales and overrides cleared — back to English")
    }

    // ═══════════════════════════════════════════════════════════════
    // MARK: - Thai Bundles (Approach 1 — setLocale)
    // ═══════════════════════════════════════════════════════════════

    // MARK: Social module — Thai
    static let thaiSocialBundle: [String: String] = [
        // ── Common actions ──
        "amity_common_button_cancel":    "ยกเลิก",
        "save":                         "บันทึก",
        "retry":                        "ลองอีกครั้ง",
        "amity_common_button_delete":    "ลบ",
        "discard":                      "ละทิ้ง",
        "leave":                        "ออก",
        "confirm":                      "ยืนยัน",
        "edit":                         "แก้ไข",
        "done":                         "เสร็จสิ้น",
        "on":                           "เปิด",
        "off":                          "ปิด",

        // ── Story ──
        "created_story_successfully":   "แชร์สตอรี่สำเร็จ",
        "crated_story_failed":          "แชร์สตอรี่ไม่สำเร็จ",
        "creating_story":               "กำลังอัปโหลด...",
        "delete_story_title":           "ลบสตอรี่นี้?",
        "delete_story_message":         "สตอรี่นี้จะถูกลบอย่างถาวร คุณจะไม่สามารถดูหรือค้นหาสตอรี่นี้ได้อีก",
        "story_deleted_toast_message":  "ลบสตอรี่แล้ว",
        "failed_story_banner_message":  "อัปโหลดไม่สำเร็จ",
        "failed_story_alert_title":     "อัปโหลดสตอรี่ไม่สำเร็จ",
        "failed_story_alert_message":   "คุณต้องการละทิ้งหรือลองอัปโหลดอีกครั้ง?",

        // ── Comments ──
        "comment_tray_component_title":         "ความคิดเห็น",
        "comment_text_field_placeholder":       "พูดอะไรดีๆ สิ...",
        "no_comment_available":                 "ยังไม่มีความคิดเห็น",
        "delete_comment_title":                 "ลบความคิดเห็น",
        "social_label_delete_comment_message":               "ความคิดเห็นนี้จะถูกลบอย่างถาวร",
        "deleted_comment_message":              "ความคิดเห็นนี้ถูกลบแล้ว",
        "edit_comment_bottom_sheet_title":      "แก้ไขความคิดเห็น",
        "delete_comment_bottom_sheet_title":    "ลบความคิดเห็น",
        "report_comment_bottom_sheet_title":    "รายงานความคิดเห็น",
        "unreport_comment_bottom_sheet_title":  "ยกเลิกรายงานความคิดเห็น",
        "comment_reported_message":             "รายงานความคิดเห็นแล้ว",
        "comment_unreported_message":           "ยกเลิกรายงานความคิดเห็นแล้ว",
        "comment_react_button_text":            "ถูกใจ",
        "comment_reacted_button_text":          "ถูกใจ",
        "comment_reply_button_text":            "ตอบกลับ",
        "comment_edited_text":                  "(แก้ไขแล้ว)",
        "view_more_reply_text":                 "ดูการตอบกลับเพิ่มเติม",
        "disable_create_comment_text":          "ปิดการแสดงความคิดเห็นสำหรับสตอรี่นี้",
        "comment_with_banned_words_error_message": "ความคิดเห็นของคุณมีคำที่ไม่เหมาะสม กรุณาตรวจสอบและลบออก",
        "comment_with_not_allowed_link_error":  "ความคิดเห็นของคุณมีลิงก์ที่ไม่อนุญาต กรุณาตรวจสอบและลบออก",

        // ── Reply ──
        "edit_reply_bottom_sheet_title":        "แก้ไขการตอบกลับ",
        "delete_reply_bottom_sheet_title":      "ลบการตอบกลับ",
        "delete_reply_title":                   "ลบการตอบกลับ",
        "delete_reply_message":                 "การตอบกลับนี้จะถูกลบอย่างถาวร",
        "report_reply_bottom_sheet_title":      "รายงานการตอบกลับ",
        "unreport_reply_bottom_sheet_title":    "ยกเลิกรายงานการตอบกลับ",
        "reply_reported_message":               "รายงานการตอบกลับแล้ว",
        "reply_unreported_message":             "ยกเลิกรายงานการตอบกลับแล้ว",
        "reply_unavailable_toast_message":      "การตอบกลับนี้ไม่มีอยู่แล้ว",
        "comment_unavailable_toast_message":    "ความคิดเห็นนี้ไม่มีอยู่แล้ว",

        // ── Post ──
        "social_label_find_community_or_create_your_own":           "ค้นหาชุมชนหรือสร้างชุมชนของคุณเอง",
        "amity_social_label_find_community_or_create_your_own":      "ค้นหาชุมชนหรือสร้างชุมชนของคุณเอง",
        "edit_post_bottom_sheet_title":         "แก้ไขโพสต์",
        "delete_post_bottom_sheet_title":       "ลบโพสต์",
        "report_post_bottom_sheet_title":       "รายงานโพสต์",
        "unreport_post_bottom_sheet_title":     "ยกเลิกรายงานโพสต์",
        "delete_post_title":                    "ลบโพสต์นี้?",
        "delete_post_message":                  "โพสต์นี้จะถูกลบอย่างถาวร คุณจะไม่สามารถดูหรือค้นหาโพสต์นี้ได้อีก",
        "post_reported_message":                "รายงานโพสต์แล้ว",
        "post_unreported_message":              "ยกเลิกรายงานโพสต์แล้ว",
        "post_deleted_toast_message":           "ลบโพสต์แล้ว",
        "post_detail_page_title":               "โพสต์",
        "post_unavailable_toast_message":       "โพสต์นี้ไม่มีอยู่แล้ว",
        "create_post_bottom_sheet_title":       "โพสต์",
        "amity_social_button_story":      "สตอรี่",

        // ── Community ──
        "community_page_join_title":            "เข้าร่วม",
        "community_page_joined_title":          "เข้าร่วมแล้ว",
        "community_page_pending_post_title":    "โพสต์รอตรวจสอบ",
        "common_label_join_community_to_interact": "เข้าร่วมชุมชนเพื่อโต้ตอบ",
        "community_setup_alert_title":          "ออกโดยไม่สร้างเสร็จ?",
        "community_setup_alert_message":        "ความคืบหน้าจะไม่ถูกบันทึกและชุมชนจะไม่ถูกสร้าง",
        "community_setup_edit_alert_title":     "มีการเปลี่ยนแปลงที่ยังไม่ได้บันทึก",
        "community_setup_edit_alert_message":   "คุณแน่ใจหรือไม่ว่าต้องการละทิ้งการเปลี่ยนแปลง? การเปลี่ยนแปลงจะหายไปเมื่อคุณออกจากหน้านี้",
        "permission_required":                  "ต้องการสิทธิ์!!",
        "camera_access_denied":                 "กรุณาอนุญาตการเข้าถึงกล้องในการตั้งค่า iOS",
        "general_anonymous":                    "ผู้ไม่ประสงค์ออกนาม",

        // ── New amity_ keys (Social) ──
        "amity_social_my_communities":                  "ชุมชนของฉัน",
        "amity_social_pending_posts_title":              "โพสต์รอตรวจสอบ",
        "amity_social_post_accepted_toast":              "ยอมรับโพสต์แล้ว",
        "amity_social_post_declined_toast":              "ปฏิเสธโพสต์แล้ว",
        "amity_social_status_host_badge":                       "โฮสต์",
        "amity_social_accept_button":                    "ยอมรับ",
        "amity_social_decline_button":                   "ปฏิเสธ",
        "amity_social_save_button":                      "บันทึก",
        "amity_social_camera_button":                    "กล้อง",
        "amity_social_photo_button":                     "รูปภาพ",
        "amity_social_edit_post":                        "แก้ไขโพสต์",
        "amity_social_edit_profile":                     "แก้ไขโปรไฟล์",
        "social_label_edit_user_display_name_title":             "ชื่อที่แสดง",
        "amity_social_tag_products":                     "แท็กสินค้า",
        "amity_social_products_tagged":                  "แท็กสินค้าแล้ว",
        "amity_social_button_add_option":                       "เพิ่มตัวเลือก",
        "amity_social_upload_image":                     "อัปโหลดรูปภาพ",
        "amity_social_upload_new_image":                 "อัปโหลดรูปภาพใหม่",
        "amity_social_image_upload_failed":              "ไม่สามารถอัปโหลดรูปภาพได้",
        "amity_social_option_n":                         "ตัวเลือก %d",
        "amity_social_choose_poll_type":                 "เลือกประเภทโพล",
        "amity_social_see_less":                         "ดูน้อยลง",
        "amity_social_cancel_request":                   "ยกเลิกคำขอ",
        "amity_social_private_community_title":          "ชุมชนนี้เป็นส่วนตัว",
        "amity_social_private_community_description":    "เข้าร่วมชุมชนนี้เพื่อดูเนื้อหาและสมาชิก",
        "amity_social_no_community_yet":                 "ยังไม่มีชุมชน",
        "amity_social_no_community_yet_description":     "มาสร้างชุมชนของคุณเองกันเถอะ",
        "amity_social_categories_label":                 "หมวดหมู่",
        "amity_social_add_category":                     "เพิ่มหมวดหมู่",
        "amity_social_add_member":                       "เพิ่มสมาชิก",
        "amity_social_no_post_to_review":                "ไม่มีโพสต์ให้ตรวจสอบ",
        "amity_social_max_upload_limit_title":           "ถึงขีดจำกัดการอัปโหลดแล้ว",
        "amity_social_max_upload_limit_message":         "คุณอัปโหลดได้สูงสุด 10 %@",
        "amity_social_content_unavailable":              "เนื้อหาที่คุณกำลังหาไม่พร้อมใช้งาน",
        "amity_social_banned_title":                     "คุณถูกแบน",
        "amity_social_banned_message":                   "จากกิจกรรมก่อนหน้า บัญชีของคุณถูกแบนจากฟีดทั้งหมด",
        "amity_social_report_thanks_title":              "ขอบคุณสำหรับการรายงาน",
        "amity_social_report_thanks_message":            "ผู้ดูแลของเราจะตรวจสอบเนื้อหานี้และดำเนินการหากละเมิดแนวทางของเรา",
        "amity_social_decline_invitation_title":         "ปฏิเสธคำเชิญ?",
        "amity_social_decline_invitation_message":       "หากคุณเปลี่ยนใจ คุณจะต้องขอเข้าร่วมใหม่",
        "amity_social_no_requests_to_review":            "ไม่มีคำขอให้ตรวจสอบ",
        "amity_social_manage_blocked_users":             "จัดการผู้ใช้ที่ถูกบล็อก",

        // ── Clip ──
        "amity_social_empty_state_social_home_empty_title":            "ฟีดของคุณว่างเปล่า",
        "amity_social_clip_explore_community":           "สำรวจชุมชน",
        "amity_social_clip_create_community":            "สร้างชุมชน",
        "amity_social_clip_unable_to_load":              "ไม่สามารถโหลดคลิปได้",
        "amity_social_clip_watch_next":                  "ดูคลิปถัดไป",
        "social_label_this_clip_is_no_longer_available":                "คลิปนี้ไม่มีอยู่แล้ว",

        // ── Story extras ──
        "amity_social_share_story":                      "แชร์สตอรี่",
        "amity_social_unsaved_changes_message":          "คุณแน่ใจหรือไม่ว่าต้องการยกเลิก? การเปลี่ยนแปลงของคุณจะไม่ถูกบันทึก",
        "amity_social_remove_link_button":               "ลบลิงก์",
        "amity_social_remove_link_title":                "ลบลิงก์?",
        "amity_social_remove_link_message":              "ลิงก์นี้จะถูกลบออกจากสตอรี่",
        "amity_social_discard_story_title":              "ละทิ้งสตอรี่?",
        "amity_social_discard_story_message":            "สตอรี่จะถูกละทิ้งอย่างถาวร ไม่สามารถยกเลิกได้",

        // ── LiveStream ──
        "livestream_player_ended_title":         "การถ่ายทอดสดนี้จบลงแล้ว",
        "livestream_player_ended_message":       "การเล่นย้อนหลังจะพร้อมให้คุณชมในเร็วๆ นี้",
        "amity_social_livestream_limited_visibility": "การถ่ายทอดสดเริ่มแล้ว แต่จะมองเห็นได้จำกัดจนกว่าโพสต์จะได้รับการอนุมัติ",
        "amity_social_livestream_join_to_interact":   "เข้าร่วมชุมชนเพื่อโต้ตอบกับการถ่ายทอดสด",

        // ── Reactions ──
        "reaction_list_unable_to_load_title":    "ไม่สามารถโหลดปฏิกิริยาได้",
        "reaction_list_no_reactions_title":       "ยังไม่มีปฏิกิริยา",
        "reaction_list_no_reactions_subtitle":    "เป็นคนแรกที่แสดงปฏิกิริยาต่อข้อความนี้!",
        "reaction_list_tap_to_remove":           "แตะเพื่อลบปฏิกิริยา",
        "reaction_tab_all":                      "ทั้งหมด",

        // ── Misc ──
        "reach_mention_limit_title":             "ไม่สามารถกล่าวถึงผู้ใช้ได้",
        "ads_sponsored_label":                   "สนับสนุน",
        "network_connectivity_status":           "กำลังรอเครือข่าย...",
    ]

    // MARK: Common module — Thai
    static let thaiCommonBundle: [String: String] = [
        // ── Reactions ──
        "amity_social_reaction_like":       "ถูกใจ",
        "amity_social_reaction_love":       "รัก",
        "amity_social_reaction_fire":       "ไฟ",
        "amity_social_reaction_happy":      "มีความสุข",
        "amity_social_reaction_sad":        "เศร้า",
        "amity_social_reaction_heart":      "หัวใจ",
        "amity_social_reaction_grinning":   "ยิ้มกว้าง",
        "amity_common_reaction_all_tab":    "ทั้งหมด",

        // ── Ads ──
        "amity_common_ad_about_title":          "เกี่ยวกับโฆษณานี้",
        "amity_common_ad_why_title":            "ทำไมจึงเห็นโฆษณานี้?",
        "amity_common_ad_why_description":      "คุณเห็นโฆษณานี้เพราะแสดงให้ผู้ใช้ทุกคนในระบบ",
        "amity_common_ad_about_advertiser":     "เกี่ยวกับผู้โฆษณา",
        "amity_common_ad_advertiser_name":      "ชื่อผู้โฆษณา: %@",
        "ads_sponsored_label":                  "สนับสนุน",

        // ── Common labels ──
        "amity_common_unknown":              "ไม่ทราบ",
        "amity_common_unknown_error":        "ข้อผิดพลาดที่ไม่ทราบ",
        "amity_common_next":                 "ถัดไป",
        "amity_social_button_keep_editing":         "แก้ไขต่อ",
        "amity_common_yes":                  "ใช่",
        "amity_common_no":                   "ไม่",
        "amity_common_remove":               "ลบออก",
        "amity_common_join":                 "เข้าร่วม",
        "amity_common_unblock":              "ปลดบล็อก",
        "amity_common_post":                 "โพสต์",
        "amity_common_view":                 "ดู",
        "amity_common_moderator":            "ผู้ดูแล",
        "amity_social_status_live":                 "สด",
        "amity_common_pending":              "รอดำเนินการ",
         "amity_social_button_social_home_clips_button":                "คลิป",
         "amity_social_tab_tab_clips":                                 "คลิป",
         "amity_common_nothing_here_yet":     "ยังไม่มีอะไรให้ดู",
        "amity_common_by_author":            "โดย %@",
        "amity_social_label_optional":       " (ไม่บังคับ)",
        "amity_common_required_indicator":   " *",
    ]

    // MARK: Chat module — Thai
    static let thaiChatBundle: [String: String] = [
        "chat_toast_loading":               "กำลังโหลดแชท...",
        "chat_toast_copied":                "คัดลอกแล้ว",
        "chat_toast_delete_error":          "ไม่สามารถลบข้อความได้ กรุณาลองอีกครั้ง",
        "chat_toast_link_not_allow":        "ข้อความของคุณไม่ถูกส่งเพราะมีลิงก์ที่ไม่อนุญาต",
        "chat_toast_banned_word":           "ข้อความของคุณไม่ถูกส่งเพราะมีคำที่ถูกบล็อก",
        "chat_toast_report_message":        "รายงานข้อความแล้ว",
        "chat_toast_un_report_message":     "ยกเลิกรายงานข้อความแล้ว",
        "chat_deleted_message_text":        "ข้อความนี้ถูกลบแล้ว",
        "chat_button_reply":                "ตอบกลับ",
        "chat_button_copy":                 "คัดลอก",
        "chat_button_delete":               "ลบ",
        "chat_button_report":               "รายงาน",
        "chat_button_un_report":            "ยกเลิกรายงาน",
        "chat_button_ok":                   "ตกลง",
        "chat_error_loading_chat_title":    "ไม่สามารถโหลดแชทได้",
        "chat_error_banned_chat_title":     "คุณถูกแบนจากแชท",
        "chat_error_banned_chat_sub_title": "คุณไม่สามารถเข้าร่วมแชทนี้ได้จนกว่าจะถูกปลดแบน",
        "chat_char_limit_alert_title":      "ไม่สามารถส่งข้อความได้",
        "chat_char_limit_alert_message":    "ข้อความของคุณยาวเกินไป กรุณาย่อข้อความแล้วลองอีกครั้ง",
        "chat_delete_alert_title":          "ลบข้อความนี้?",
        "chat_delete_alert_message":        "ข้อความนี้จะถูกลบจากอุปกรณ์ของเพื่อนคุณด้วย",
        "chat_user_is_muted":              "คุณถูกปิดเสียงโดยผู้ดูแลช่อง",
        "chat_channel_is_muted":           "ช่องนี้ถูกตั้งค่าเป็นอ่านอย่างเดียวโดยผู้ดูแลช่อง",
        "chat_sending_status":              "กำลังส่ง...",
        "chat_mention_everyone":            "แจ้งเตือนทุกคน",
        "chat_reply_preview":               "กำลังตอบกลับ %@",
        "chat_member_count":                "%@ สมาชิก",
        "amity_chat_edit_message":          "แก้ไขข้อความ",
        "network_connectivity_status":      "กำลังรอเครือข่าย...",
    ]

    // ═══════════════════════════════════════════════════════════════
    // MARK: - Italian Overrides (Approach 2 — setOverrides)
    // ═══════════════════════════════════════════════════════════════

    // MARK: Social module — Italian
    static let italianSocialOverrides: [String: String] = [
        // ── Common actions ──
        "amity_common_button_cancel":    "Annulla",
        "save":                         "Salva",
        "retry":                        "Riprova",
        "amity_common_button_delete":    "Elimina",
        "discard":                      "Scarta",
        "leave":                        "Esci",
        "confirm":                      "Conferma",
        "edit":                         "Modifica",
        "done":                         "Fatto",
        "on":                           "Attivo",
        "off":                          "Disattivo",

        // ── Story ──
        "created_story_successfully":   "Storia condivisa con successo",
        "crated_story_failed":          "Condivisione storia non riuscita",
        "creating_story":               "Caricamento...",
        "delete_story_title":           "Eliminare questa storia?",
        "delete_story_message":         "Questa storia verrà eliminata definitivamente. Non potrai più vederla o trovarla.",
        "story_deleted_toast_message":  "Storia eliminata",
        "failed_story_banner_message":  "Caricamento non riuscito",
        "failed_story_alert_title":     "Caricamento storia non riuscito",
        "failed_story_alert_message":   "Vuoi scartare o riprovare il caricamento?",

        // ── Comments ──
        "comment_tray_component_title":         "Commenti",
        "comment_text_field_placeholder":        "Scrivi qualcosa di carino...",
        "no_comment_available":                  "Nessun commento ancora",
        "delete_comment_title":                  "Elimina commento",
        "social_label_delete_comment_message":                "Questo commento verrà eliminato definitivamente.",
        "deleted_comment_message":               "Questo commento è stato eliminato",
        "edit_comment_bottom_sheet_title":       "Modifica commento",
        "delete_comment_bottom_sheet_title":     "Elimina commento",
        "report_comment_bottom_sheet_title":     "Segnala commento",
        "unreport_comment_bottom_sheet_title":   "Annulla segnalazione commento",
        "comment_reported_message":              "Commento segnalato",
        "comment_unreported_message":            "Segnalazione commento annullata",
        "comment_react_button_text":             "Mi piace",
        "comment_reacted_button_text":           "Mi piace",
        "comment_reply_button_text":             "Rispondi",
        "comment_edited_text":                   "(modificato)",
        "view_more_reply_text":                  "Mostra altre risposte",
        "disable_create_comment_text":           "I commenti sono disabilitati per questa storia",
        "comment_with_banned_words_error_message": "Il tuo commento contiene parole inappropriate. Controlla ed eliminale.",
        "comment_with_not_allowed_link_error":   "Il tuo commento contiene un link non consentito. Controlla ed eliminalo.",

        // ── Reply ──
        "edit_reply_bottom_sheet_title":        "Modifica risposta",
        "delete_reply_bottom_sheet_title":      "Elimina risposta",
        "delete_reply_title":                   "Elimina risposta",
        "delete_reply_message":                 "Questa risposta verrà eliminata definitivamente.",
        "report_reply_bottom_sheet_title":      "Segnala risposta",
        "unreport_reply_bottom_sheet_title":    "Annulla segnalazione risposta",
        "reply_reported_message":               "Risposta segnalata",
        "reply_unreported_message":             "Segnalazione risposta annullata",
        "reply_unavailable_toast_message":      "Questa risposta non è più disponibile",
        "comment_unavailable_toast_message":    "Questo commento non è più disponibile.",

        // ── Post ──
        "social_label_find_community_or_create_your_own":           "Trova una comunità o creane una tua",
        "amity_social_label_find_community_or_create_your_own":      "Trova una comunità o creane una tua",
        "edit_post_bottom_sheet_title":         "Modifica post",
        "delete_post_bottom_sheet_title":       "Elimina post",
        "report_post_bottom_sheet_title":       "Segnala post",
        "unreport_post_bottom_sheet_title":     "Annulla segnalazione post",
        "delete_post_title":                    "Eliminare questo post?",
        "delete_post_message":                  "Questo post verrà eliminato definitivamente. Non potrai più vederlo o trovarlo.",
        "post_reported_message":                "Post segnalato.",
        "post_unreported_message":              "Segnalazione post annullata.",
        "post_deleted_toast_message":           "Post eliminato.",
        "post_detail_page_title":               "Post",
        "post_unavailable_toast_message":       "Questo post non è più disponibile.",
        "create_post_bottom_sheet_title":       "Post",
        "amity_social_button_story":      "Storia",

        // ── Community ──
        "community_page_join_title":            "Unisciti",
        "community_page_joined_title":          "Iscritto",
        "community_page_pending_post_title":    "Post in attesa",
        "common_label_join_community_to_interact": "Unisciti alla comunità per interagire.",
        "community_setup_alert_title":          "Uscire senza completare?",
        "community_setup_alert_message":        "I tuoi progressi non verranno salvati e la comunità non verrà creata.",
        "community_setup_edit_alert_title":     "Modifiche non salvate",
        "community_setup_edit_alert_message":   "Sei sicuro di voler scartare le modifiche? Verranno perse quando esci da questa pagina.",
        "permission_required":                  "Permesso necessario!!",
        "camera_access_denied":                 "Concedi il permesso della fotocamera nelle impostazioni iOS.",
        "general_anonymous":                    "Anonimo",

        // ── New amity_ keys (Social) ──
        "amity_social_my_communities":                  "Le mie comunità",
        "amity_social_pending_posts_title":              "Post in attesa",
        "amity_social_post_accepted_toast":              "Post accettato.",
        "amity_social_post_declined_toast":              "Post rifiutato.",
        "amity_social_status_host_badge":                       "Organizzatore",
        "amity_social_accept_button":                    "Accetta",
        "amity_social_decline_button":                   "Rifiuta",
        "amity_social_save_button":                      "Salva",
        "amity_social_camera_button":                    "Fotocamera",
        "amity_social_photo_button":                     "Foto",
        "amity_social_edit_post":                        "Modifica post",
        "amity_social_edit_profile":                     "Modifica profilo",
        "social_label_edit_user_display_name_title":             "Nome visualizzato",
        "amity_social_tag_products":                     "Tagga prodotti",
        "amity_social_products_tagged":                  "Prodotti taggati",
        "amity_social_button_add_option":                       "Aggiungi opzione",
        "amity_social_upload_image":                     "Carica immagine",
        "amity_social_upload_new_image":                 "Carica nuova immagine",
        "amity_social_image_upload_failed":              "Impossibile caricare l'immagine",
        "amity_social_option_n":                         "Opzione %d",
        "amity_social_choose_poll_type":                 "Scegli tipo di sondaggio",
        "amity_social_see_less":                         "Mostra meno",
        "amity_social_cancel_request":                   "Annulla richiesta",
        "amity_social_private_community_title":          "Questa comunità è privata",
        "amity_social_private_community_description":    "Unisciti a questa comunità per vederne i contenuti e i membri.",
        "amity_social_no_community_yet":                 "Nessuna comunità ancora",
        "amity_social_no_community_yet_description":     "Crea le tue comunità",
        "amity_social_categories_label":                 "Categorie",
        "amity_social_add_category":                     "Aggiungi categoria",
        "amity_social_add_member":                       "Aggiungi membro",
        "amity_social_no_post_to_review":                "Nessun post da revisionare",
        "amity_social_max_upload_limit_title":           "Limite di caricamento raggiunto",
        "amity_social_max_upload_limit_message":         "Hai raggiunto il limite di caricamento di 10 %@",
        "amity_social_content_unavailable":              "Il contenuto che cerchi non è disponibile.",
        "amity_social_banned_title":                     "Sei stato bannato.",
        "amity_social_banned_message":                   "In base alle tue attività precedenti, il tuo account è stato bannato da tutti i feed.",
        "amity_social_report_thanks_title":              "Grazie per la segnalazione.",
        "amity_social_report_thanks_message":            "I nostri moderatori esamineranno questo contenuto e interverranno se viola le nostre linee guida.",
        "amity_social_decline_invitation_title":         "Rifiutare l'invito?",
        "amity_social_decline_invitation_message":       "Se cambi idea, dovrai richiedere di nuovo l'adesione.",
        "amity_social_no_requests_to_review":            "Nessuna richiesta da revisionare",
        "amity_social_manage_blocked_users":             "Gestisci utenti bloccati",

        // ── Clip ──
        "amity_social_empty_state_social_home_empty_title":            "Il tuo feed è vuoto",
        "amity_social_clip_explore_community":           "Esplora comunità",
        "amity_social_clip_create_community":            "Crea comunità",
        "amity_social_clip_unable_to_load":              "Impossibile caricare il clip",
        "amity_social_clip_watch_next":                  "Guarda il prossimo clip",
        "social_label_this_clip_is_no_longer_available":                "Questo clip non è più disponibile.",

        // ── Story extras ──
        "amity_social_share_story":                      "Condividi storia",
        "amity_social_unsaved_changes_message":          "Sei sicuro di voler annullare? Le modifiche non verranno salvate.",
        "amity_social_remove_link_button":               "Rimuovi link",
        "amity_social_remove_link_title":                "Rimuovere il link?",
        "amity_social_remove_link_message":              "Questo link verrà rimosso dalla storia.",
        "amity_social_discard_story_title":              "Scartare la storia?",
        "amity_social_discard_story_message":            "La storia verrà scartata definitivamente. Non è possibile annullare.",

        // ── LiveStream ──
        "livestream_player_ended_title":         "Questa diretta è terminata.",
        "livestream_player_ended_message":       "La registrazione sarà disponibile a breve.",
        "amity_social_livestream_limited_visibility": "La diretta è iniziata, ma con visibilità limitata fino all'approvazione del post.",
        "amity_social_livestream_join_to_interact":   "Unisciti alla comunità per interagire con la diretta.",

        // ── Reactions ──
        "reaction_list_unable_to_load_title":    "Impossibile caricare le reazioni",
        "reaction_list_no_reactions_title":       "Nessuna reazione ancora",
        "reaction_list_no_reactions_subtitle":    "Sii il primo a reagire a questo messaggio!",
        "reaction_list_tap_to_remove":           "Tocca per rimuovere la reazione",
        "reaction_tab_all":                      "Tutti",

        // ── Misc ──
        "reach_mention_limit_title":             "Impossibile menzionare l'utente",
        "ads_sponsored_label":                   "Sponsorizzato",
        "network_connectivity_status":           "In attesa della rete...",
    ]

    // MARK: Common module — Italian
    static let italianCommonOverrides: [String: String] = [
        // ── Reactions ──
        "amity_social_reaction_like":       "Mi piace",
        "amity_social_reaction_love":       "Amore",
        "amity_social_reaction_fire":       "Fuoco",
        "amity_social_reaction_happy":      "Felice",
        "amity_social_reaction_sad":        "Triste",
        "amity_social_reaction_heart":      "Cuore",
        "amity_social_reaction_grinning":   "Sorridente",
        "amity_common_reaction_all_tab":    "Tutti",

        // ── Ads ──
        "amity_common_ad_about_title":          "Informazioni su questa pubblicità",
        "amity_common_ad_why_title":            "Perché questa pubblicità?",
        "amity_common_ad_why_description":      "Stai vedendo questa pubblicità perché è stata mostrata a tutti gli utenti del sistema.",
        "amity_common_ad_about_advertiser":     "Informazioni sull'inserzionista",
        "amity_common_ad_advertiser_name":      "Nome inserzionista: %@",
        "ads_sponsored_label":                  "Sponsorizzato",

        // ── Common labels ──
        "amity_common_unknown":              "Sconosciuto",
        "amity_common_unknown_error":        "Errore sconosciuto",
        "amity_common_next":                 "Avanti",
        "amity_social_button_keep_editing":         "Continua a modificare",
        "amity_common_yes":                  "Sì",
        "amity_common_no":                   "No",
        "amity_common_remove":               "Rimuovi",
        "amity_common_join":                 "Unisciti",
        "amity_common_unblock":              "Sblocca",
        "amity_common_post":                 "Post",
        "amity_common_view":                 "Visualizza",
        "amity_common_moderator":            "Moderatore",
        "amity_social_status_live":                 "IN DIRETTA",
        "amity_common_pending":              "In attesa",
         "amity_social_button_social_home_clips_button":                "Clip",
         "amity_social_tab_tab_clips":                                 "Clip",
         "amity_common_nothing_here_yet":     "Non c'è ancora niente da vedere",
        "amity_common_by_author":            "Di %@",
        "amity_social_label_optional":       " (Facoltativo)",
        "amity_common_required_indicator":   " *",
    ]

    // MARK: Chat module — Italian
    static let italianChatOverrides: [String: String] = [
        "chat_toast_loading":               "Caricamento chat...",
        "chat_toast_copied":                "Copiato",
        "chat_toast_delete_error":          "Impossibile eliminare il messaggio. Riprova.",
        "chat_toast_link_not_allow":        "Il tuo messaggio non è stato inviato perché conteneva un link non consentito.",
        "chat_toast_banned_word":           "Il tuo messaggio non è stato inviato perché conteneva una parola bloccata.",
        "chat_toast_report_message":        "Messaggio segnalato.",
        "chat_toast_un_report_message":     "Segnalazione messaggio annullata.",
        "chat_deleted_message_text":        "Questo messaggio è stato eliminato",
        "chat_button_reply":                "Rispondi",
        "chat_button_copy":                 "Copia",
        "chat_button_delete":               "Elimina",
        "chat_button_report":               "Segnala",
        "chat_button_un_report":            "Annulla segnalazione",
        "chat_button_ok":                   "OK",
        "chat_error_loading_chat_title":    "Impossibile caricare la chat",
        "chat_error_banned_chat_title":     "Sei stato bannato dalla chat",
        "chat_error_banned_chat_sub_title": "Non potrai partecipare a questa chat finché non sarai sbannato.",
        "chat_char_limit_alert_title":      "Impossibile inviare il messaggio",
        "chat_char_limit_alert_message":    "Il tuo messaggio è troppo lungo. Accorcialo e riprova.",
        "chat_delete_alert_title":          "Eliminare questo messaggio?",
        "chat_delete_alert_message":        "Questo messaggio verrà rimosso anche dai dispositivi dei tuoi amici.",
        "chat_user_is_muted":              "Sei stato silenziato dal moderatore del canale.",
        "chat_channel_is_muted":           "Questo canale è stato impostato in sola lettura dal moderatore.",
        "chat_sending_status":              "Invio in corso...",
        "chat_mention_everyone":            "Notifica a tutti",
        "chat_reply_preview":               "Rispondendo a %@",
        "chat_member_count":                "%@ membri",
        "amity_chat_edit_message":          "Modifica messaggio",
        "network_connectivity_status":      "In attesa della rete...",
    ]
}
