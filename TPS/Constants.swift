//
//  Constants.swift
//  TPS
//
//  Created by Steve Leeke on 11/4/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

struct Constants {
    static let iosBlueColor = UIColor(colorLiteralRed: 0.0, green:122.0/255.0, blue:1.0, alpha:1.0)
    
    static let CACHE_POLICY = NSURLRequestCachePolicy.ReturnCacheDataElseLoad
    static let CACHE_TIMEOUT = 1.0
    
    static let SKIP_TIME_INTERVAL = 15
    
    static let JSON_ARRAY_KEY = "sermons"
    static let JSON_URL_PREFIX = "https://s3.amazonaws.com/jd2-86d4fd0ec0a8fca71eef54e388261c5b-us/"
    static let SERMONS_JSON = "sermons.json"
    static let SERMONS_ARCHIVE = "sermons.archive"
    
    static let CACHE = "cache"

    static let LIVE_STREAM_URL = "http://content.uplynk.com/channel/bd25cb880ed84b4db3061b9ad16b5a3c.m3u8"
    
    static let COVER_ART_IMAGE = "cover170x170"
    
    static let SERMON_UPDATE_UI_NOTIFICATION = "SERMON UPDATE UI"
    
    static let HEADER_HEIGHT = CGFloat(48)
    static let VIEW_TRANSITION_TIME = 0.75 // seconds
    static let ZERO = "0"
    
    static let POPOVER_CELL_IDENTIFIER = "PopoverCell"
    static let POPOVER_TABLEVIEW_IDENTIFIER = "PopoverTableView"
    
    static let SERMONS_CELL_IDENTIFIER = "Sermons"
    static let SERMONS_IN_SERIES_CELL_IDENTIFIER = "SermonSeries"
    
    static let SHOW_TRANSCRIPT_FULL_SCREEN_SEGUE_IDENTIFIER = "Show Full Screen"
    
    static let NOTES_CONTENT_OFFSET_X_RATIO = "notesContentOffsetXRatio"
    static let NOTES_CONTENT_OFFSET_Y_RATIO = "notesContentOffsetYRatio"
    
    static let NOTES_ZOOM_SCALE = "notesZoomScale"
    
    static let SLIDES_CONTENT_OFFSET_X_RATIO = "slidesContentOffsetXRatio"
    static let SLIDES_CONTENT_OFFSET_Y_RATIO = "slidesContentOffsetYRatio"
    
    static let SLIDES_ZOOM_SCALE = "slidesZoomScale"
    
    static let CBC_SHORT = "CBC"
    static let CBC_LONG = "Countryside Bible Church"
    
    static let Sermons = "Sermons"
    
    static let CBC_LONG_TITLE = Constants.CBC_LONG + Constants.SINGLE_SPACE_STRING + Constants.Sermons
    static let CBC_SHORT_TITLE = Constants.CBC_SHORT + Constants.SINGLE_SPACE_STRING + Constants.Sermons
    
    static let EMAIL_SUBJECT = Constants.CBC_LONG
    static let SERMON_EMAIL_SUBJECT = "Recommendation"
    static let SERIES_EMAIL_SUBJECT = Constants.SERMON_EMAIL_SUBJECT
    
    static let CBC_EMAIL = "cbcstaff@countrysidebible.org"
    static let CBC_WEBSITE = "http://www.countrysidebible.org"
    static let CBC_STREET_ADDRESS = "250 Countryside Court"
    static let CBC_CITY_STATE_ZIPCODE_COUNTRY = "Southlake, TX 76092, USA"
    static let CBC_PHONE_NUMBER = "(817) 488-5381"
    static let CBC_FULL_ADDRESS = Constants.CBC_STREET_ADDRESS + ", " + Constants.CBC_CITY_STATE_ZIPCODE_COUNTRY
    
    static let CBC_TITLE_POSTFIX = " Sermons"
    
    static let CBC_TITLE_SHORT = Constants.CBC_SHORT + Constants.CBC_TITLE_POSTFIX
    static let CBC_TITLE_LONG = Constants.CBC_LONG + Constants.CBC_TITLE_POSTFIX
    
    static let Network_Unavailable = "Network Unavailable"
    static let Content_Failed_to_Load = "Content Failed to Load"
    
    static let TAGGED = "tagged"
    static let ALL = "all"
    
    static let ID = "id"
    static let DATE = "date"
    static let SERVICE = "service"
    static let TITLE = "title"
    static let NAME = "name"
    
    static let SPEAKER = "speaker"
    static let SPEAKER_SORT = "speaker sort"
    
    static let SCRIPTURE = "scripture"
    static let Scripture = "Scripture"
    
    static let SERIES = "series"
    static let SERIES_SORT = "series sort"
    
    static let TAGS = "tags"
    static let AUDIO = "audio"
    static let VIDEO = "video"
    static let NOTES = "notes"
    static let SLIDES = "slides"
    
    static let NONE = "none"
    
    static let SERMON_PLAYING = "sermon playing"
    static let CURRENT_TIME = "current time"
    
    static let EMPTY_STRING = ""
    static let SINGLE_SPACE_STRING = " "
    static let SINGLE_UNDERSCORE_STRING = "_"
    
    static let FORWARD_SLASH = "/"
    
    static let TAGS_SEPARATOR = "|"
    
    static let PLAYING = "playing"
    static let SHOWING = "showing"
    
    static let SORTING = "sorting"
    static let GROUPING = "grouping"
    
    static let COLLECTION = "collection"
    
    static let Sorting = "Sorting"
    static let Grouping = "Grouping"
    static let Index = "Index"
    
    static let Options = "Options"
    
    static let Sorting_Options =  Constants.Sorting + Constants.SINGLE_SPACE_STRING + Constants.Options
    static let Grouping_Options = Constants.Grouping + Constants.SINGLE_SPACE_STRING + Constants.Options
    
    static let SERMON_SETTINGS_KEY = "Sermon Settings"
    static let SERIES_VIEW_SPLITS_KEY = "Series View Splits"
    
    static let SELECTED_SERMON_KEY = "selectedSermonKey"
    static let SELECTED_SERMON_DETAIL_KEY = "selectedSermonDetailKey"
    
    static let Year = "Year"
    static let YEAR = "year"
    
    static let Book = "Book"
    static let BOOK = "book"
    
    static let Speaker = "Speaker"
    static let Series = "Series"
    
    static let CHRONOLOGICAL = "chronological"
    static let Chronological = "Chronological"
    
    static let REVERSE_CHRONOLOGICAL = "reverse chronological"
    static let Reverse_Chronological = "Reverse Chronological"
    
    static let MIN_SLIDER_WIDTH = CGFloat(60)
    static let MIN_STV_SEGMENT_WIDTH = CGFloat(20)
    
    static let Selected_Scriptures = "Selected Scriptures"
    static let Individual_Sermons = "Individual Sermons"
    
    static let AUDIO_SEGMENT_INDEX = 0
    static let VIDEO_SEGMENT_INDEX = 1
    
    static let AUDIO_VIDEO_MAX_WIDTH = CGFloat(40)
    
    // first.service < second.service relies upon the face that AM and PM are alphabetically sorted the same way they are related chronologically, i.e. AM comes before PM in both cases.
    static let MORNING_SERVICE = "AM"
    static let EVENING_SERVICE = "PM"
    
    static let FontAwesome = "FontAwesome"
    
    static let FA_ICONS_FONT_SIZE = CGFloat(12.0)
    static let FA_SLIDES = "\u{f022}"
    static let FA_TRANSCRIPT = "\u{f0f6}"
    static let FA_AUDIO = "\u{f025}"
    static let FA_VIDEO = "\u{f03d}"
    
    static let FA_DOWNLOAD_FONT_SIZE = CGFloat(18.0)
    static let FA_DOWNLOAD = "\u{f019}"
    static let FA_DOWNLOADING = "\u{f0ae}"
    static let FA_DOWNLOADED = "\u{f1c7}"
    static let FA_CLOUD_DOWNLOAD = "\u{f0ed}"
    
    static let Download_Audio = "Download Audio"
    static let Download_All_Audio = "Download All Audio"
    static let Cancel_All_Downloads = "Cancel All Downloads"
    static let Delete_All_Downloads = "Delete All Downloads"
    
    static let FA_PLAY_PLAUSE_FONT_SIZE = CGFloat(24.0)
    static let FA_PLAY = "\u{f04b}"
    static let FA_PAUSE = "\u{f04c}"
    
    static let FA_SLIDES_SEGMENT_TITLE = Constants.FA_SLIDES
    static let FA_TRANSCRIPT_SEGMENT_TITLE = Constants.FA_TRANSCRIPT
    static let FA_VIDEO_SEGMENT_TITLE = Constants.FA_VIDEO
    
    static let SLIDES_SEGMENT_TITLE = "S"
    static let TRANSCRIPT_SEGMENT_TITLE = "T"
    static let VIDEO_SEGMENT_TITLE = "V"
    
    static let Cancel_Audio_Download = "Cancel Audio Download?"
    static let Delete_Audio_Download = "Delete Downloaded Audio?"
    
    static let REACHABILITY_TEST_URL = "https://www.google.com/"
    
    static let BASE_AUDIO_URL = "http://sitedata.countrysidebible.org/avmedia/se/"
    static let BASE_PDF_URL = "http://sitedata.countrysidebible.org/avmedia/dc/"
    static let BASE_VIDEO_URL_PREFIX = "https://player.vimeo.com/external/"
    static let BASE_VIDEO_URL_POSTFIX = "&profile_id=113"
    
    static let BASE_DOWNLOAD_URL:String = "http://sitedata.countrysidebible.org/avmedia/se/download.php?file="
    
    static let SCRIPTURE_URL_PREFIX = "http://www.biblegateway.com/passage/?search="
    static let SCRIPTURE_URL_POSTFIX = "&version=NASB"
    
    static let TRANSCRIPT_PREFIX = "tx-un-"
    static let PDF_FILE_EXTENSION = ".pdf"
    
    static let All = "All"
    static let None = "None"
    static let Okay = "OK"
    static let Cancel = "Cancel"
    static let About = "About"
    static let Current_Selection = "Current Selection"
    static let Tags = "Tags"
    
    static let Back = "Back"

    static let Sermon_Playing = "Sermon Playing"
    static let Sermon_Paused = "Sermon Paused"
    
    static let Show_Sermon = "Show Sermon"
    static let Show_About = "Show About"
    
    static let Print = "Print"
    
    static let Full_Screen = "Full Screen"
    static let Open_in_Browser = "Open in Browser"
    
    static let Email_Sermon = "E-mail Sermon"
    static let Email_Series = "E-mail Series"
    
    static let Share_on_Facebook = "Share on Facebook"
    static let Share_on_Twitter = "Share on Twitter"

    static let Play = "Play"
    static let Pause = "Pause"
    
    static let Playing = "Playing"
    static let Paused = "Paused"
    
    static let DOWNLOAD_IDENTIFIER = "com.leeke.CBC.download."
    
    static let MP3_FILENAME_EXTENSION = ".mp3"
    static let MP4_FILENAME_EXTENSION = ".mp4"
    static let TMP_FILE_EXTENSION = ".tmp"
    
    static let OLD_TESTAMENT:[String] = [
        "Genesis",
        "Exodus",
        "Leviticus",
        "Numbers",
        "Deuteronomy",
        "Joshua",
        "Judges",
        "Ruth",
        "1 Samuel",
        "2 Samuel",
        "1 Kings",
        "2 Kings",
        "1 Chronicles",
        "2 Chronicles",
        "Ezra",
        "Nehemiah",
        "Esther",
        "Job",
        "Psalm",
        "Proverbs",
        "Ecclesiastes",
        "Song of Solomon",
        "Isaiah",
        "Jeremiah",
        "Lamentations",
        "Ezekiel",
        "Daniel",
        "Hosea",
        "Joel",
        "Amos",
        "Obadiah",
        "Jonah",
        "Micah",
        "Nahum",
        "Habakkuk",
        "Zephaniah",
        "Haggai",
        "Zechariah",
        "Malachi"
    ]
    
    static let NEW_TESTAMENT:[String] = [
        "Matthew",
        "Mark",
        "Luke",
        "John",
        "Acts",
        "Romans",
        "1 Corinthians",
        "2 Corinthians",
        "Galatians",
        "Ephesians",
        "Philippians",
        "Colossians",
        "1 Thessalonians",
        "2 Thessalonians",
        "1 Timothy",
        "2 Timothy",
        "Titus",
        "Philemon",
        "Hebrews",
        "James",
        "1 Peter",
        "2 Peter",
        "1 John",
        "2 John",
        "3 John",
        "Jude",
        "Revelation"
    ]
}
