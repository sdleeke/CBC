//
//  Constants.swift
//  TPS
//
//  Created by Steve Leeke on 11/4/15.
//  Copyright © 2015 Steve Leeke. All rights reserved.
//

import Foundation
import UIKit

struct Field {
    static let id = "mediacode"
    
    static let date = "date"
    static let service = "service"
    
    static let title = "title"
    
    static let name = "name"
    
    static let audio = "audio_url"
    static let video = "m3u8"
    
    static let notes = "transcript"
    static let slides = "slides"
    static let outline = "outline"
    
    static let files = "files"

    static let playing = "playing"
    static let showing = "showing"
    
    static let speaker = "teacher" // was "speaker"
    static let speaker_sort = "speaker sort"
    
    static let scripture = "text" // was "scripture"
    static let category = "category"
    
    static let series = "NA"
    static let series_sort = "series sort"

    static let part = "part"
    static let tags = "series"
    static let book = "book"
    static let year = "year"
}

struct Media {
    static let AUDIO = "AUDIO"
    static let VIDEO = "VIDEO"
    static let SLIDES = "SLIDES"
    static let NOTES = "NOTES"
    static let OUTLINE = "OUTLINE"
    
    static let NONE = "none"
}

struct Purpose {
    static let audio = Media.AUDIO
    static let video = Media.VIDEO
    static let slides = Media.SLIDES
    static let notes = Media.NOTES
    static let outline = Media.OUTLINE
}

struct Playing {
    static let audio = Media.AUDIO
    static let video = Media.VIDEO
}

struct Showing {
    static let video = Media.VIDEO
    static let notes = Media.NOTES
    static let slides = Media.SLIDES
    static let none = Media.NONE
}

struct Grouping {
    static let Year = "Year"
    static let Book = "Book"
    static let Speaker = "Speaker"
    static let Title = "Title"

    static let YEAR = "year"
    static let BOOK = "book"
    static let SPEAKER = "speaker"
    static let TITLE = "title"
}

struct Constants {
//    static let JSON_URL_PREFIX = "https://s3.amazonaws.com/jd2-86d4fd0ec0a8fca71eef54e388261c5b-us/"
    static let JSON_BASE_URL = "http://dev.countrysidebible.org/medialist_all.php?return="

    static let JSON_MEDIA_PATH = "media" //
    
    static let JSON_MEDIA_URL = JSON_BASE_URL + JSON_MEDIA_PATH //
    
    static let JSON_CATEGORIES_PATH = "categories" //
    
    static let JSON_CATEGORIES_URL = JSON_BASE_URL + JSON_CATEGORIES_PATH //
    
    static let JSON_CATEGORY_URL = JSON_MEDIA_URL + "&categoryID=" //
    
    static let JSON_SERMONS_URL = JSON_CATEGORY_URL + globals.sermonCategoryID! //
    
    static let SINGLE_JSON_URL = "http://dev.countrysidebible.org/medialist_all.php?return=single&mediacode="
    
    static let BASE_MEDIA_URL = "http://sitedata.countrysidebible.org/avmedia/"
    
//    static let BASE_AUDIO_URL = "http://sitedata.countrysidebible.org/avmedia/se/"
//    static let BASE_PDF_URL = "http://sitedata.countrysidebible.org/avmedia/dc/"

//    static let BASE_VIDEO_URL_PREFIX = "https://player.vimeo.com/external/"
    
//    Slides: {year}/{mediacode}slides.pdf
//    Outline: {year}/{mediacode}outline.pdf
//    Transcript: {year}/{mediacode}transcript.pdf
    
//    static let BASE_DOWNLOAD_URL:String = "http://sitedata.countrysidebible.org/avmedia/se/download.php?file="
    
    static let UPDATE_PLAY_PAUSE_NOTIFICATION = "UPDATE PLAY PAUSE"
    
    static let MIN_PLAY_TIME = 15.0
    static let MIN_LOAD_TIME = 30.0
    
    static let SLIDER_TIMER_INTERVAL = 0.5
    static let PLAYER_TIMER_INTERVAL = 0.2
    static let DOWNLOADING_TIMER_INTERVAL = 0.2
    static let LOADING_TIMER_INTERVAL = 0.2
    static let PROGRESS_TIMER_INTERVAL = 0.1
    static let WORKING_TIMER_INTERVAL = 0.1
    static let SEEKING_TIMER_INTERVAL = 0.1
    
    static let JSON_CATEGORIES_ARRAY_KEY = "categoryEntries"
    static let JSON_SERMONS_ARRAY_KEY = "mediaEntries"
    static let JSON_SINGLE_ARRAY_KEY = "singleEntry"

    static let JSON_TYPE = "json"
    static let JSON_FILENAME_EXTENSION = ".json"

    static let CATEGORIES_JSON_FILENAME = JSON_CATEGORIES_ARRAY_KEY + JSON_FILENAME_EXTENSION
    static let SERMONS_JSON_FILENAME = JSON_SERMONS_ARRAY_KEY + JSON_FILENAME_EXTENSION

    static let DICT = "dict"

    static let SERIES_INDICATOR_SINGULAR = " (Part "
    
    static let LIVE_STREAM_URL = "http://content.uplynk.com/channel/bd25cb880ed84b4db3061b9ad16b5a3c.m3u8"
    
    static let REACHABILITY_TEST_URL = "http://www.countrysidebible.org/"
    
    static let Downloading_Sermons = "Downloading Sermons"
    static let Loading_Sermons = "Loading"
    static let Synthesizing_Tags = "Synthesizing Tags"
    static let Loading_Settings = "Loading Settings"
    static let Sorting_and_Grouping = "Sorting and Grouping"
    static let Setting_up_Player = "Setting up Player"
    
    static let COVER_ART_IMAGE = "cover170x170"
    
    static let CACHE_POLICY = NSURLRequest.CachePolicy.reloadRevalidatingCacheData
    static let CACHE_TIMEOUT = 10.0
    
    static let UPDATE_VIEW_NOTIFICATION = "UPDATE VIEW"
    static let CLEAR_VIEW_NOTIFICATION = "CLEAR VIEW"

    static let SERMON_UPDATE_UI_NOTIFICATION = "SERMON UPDATE UI"
    
    static let UPDATE_SERMON_LIST_NOTIFICATION = "UPDATE SERMON LIST"
    
    static let HEADER_HEIGHT = CGFloat(48)
    static let VIEW_TRANSITION_TIME = 0.75 // seconds
    
    static let PLAY_OBSERVER_TIME_INTERVAL = 10.0 // seconds

    static let SKIP_TIME_INTERVAL = 15
    static let ZERO = "0"

    static let AUTO_ADVANCE = "AUTO_ADVANCE"
    static let CACHE_DOWNLOADS = "CACHE DOWNLOADS"
    static let MEDIA_CATEGORY = "MEDIA CATEGORY"
    
    static let SEARCH_TEXT = "SEARCH TEXT"
    
    static let POPOVER_CELL_IDENTIFIER = "PopoverCell"
    static let POPOVER_TABLEVIEW_IDENTIFIER = "PopoverTableView"
    
    static let SERMONS_CELL_IDENTIFIER = "Sermons"
    static let SERMONS_IN_SERIES_CELL_IDENTIFIER = "SermonSeries"
    
    static let Live = "Live"
    
    static let CONTENT_OFFSET_X_RATIO = "ContentOffsetXRatio"
    static let CONTENT_OFFSET_Y_RATIO = "ContentOffsetYRatio"
    
    static let ZOOM_SCALE = "ZoomScale"
    
    static let CBC_SHORT = "CBC"
    static let CBC_LONG = "Countryside Bible Church"
    
    static let Email_CBC = "E-mail " + CBC_SHORT
    static let CBC_in_Apple_Maps = CBC_SHORT + " in Apple Maps"
    static let CBC_in_Google_Maps = CBC_SHORT + " in Google Maps"

    static let Sermon = "Media"
    static let Sermons = "Media"
    
    static let CBC_LONG_TITLE = CBC_LONG + SINGLE_SPACE_STRING + Sermons
    static let CBC_SHORT_TITLE = CBC_SHORT + SINGLE_SPACE_STRING + Sermons
    
    static let EMAIL_SUBJECT = CBC_LONG
    static let SERMON_EMAIL_SUBJECT = "Recommendation"
    static let SERIES_EMAIL_SUBJECT = SERMON_EMAIL_SUBJECT
    
    static let CBC_EMAIL = "cbcstaff@countrysidebible.org"
    static let CBC_WEBSITE = "http://www.countrysidebible.org"
    static let CBC_STREET_ADDRESS = "250 Countryside Court"
    static let CBC_CITY_STATE_ZIPCODE_COUNTRY = "Southlake, TX 76092, USA"
    static let CBC_PHONE_NUMBER = "(817) 488-5381"
    static let CBC_FULL_ADDRESS = CBC_STREET_ADDRESS + ", " + CBC_CITY_STATE_ZIPCODE_COUNTRY
    
    static let CBC_TITLE_POSTFIX = " " + Sermons
    
    static let CBC_TITLE_SHORT = CBC_SHORT + CBC_TITLE_POSTFIX
    static let CBC_TITLE_LONG = CBC_LONG + CBC_TITLE_POSTFIX
    
    static let Network_Error = "Network Error"
    static let Content_Failed_to_Load = "Content Failed to Load"
    
    static let TAGGED = "tagged"
    static let ALL = "all"
    static let DOWNLOADED = "downloaded"

//    static let Scripture_Full_Screen = "Scripture Full Screen"
    static let Scripture_in_Browser = "Scripture in Browser"
    
    static let SERMON_PLAYING = "sermon playing"
    static let CURRENT_TIME = "current time"
    
    static let EMPTY_STRING = ""
    static let SINGLE_SPACE_STRING = " "
    static let SINGLE_UNDERSCORE_STRING = "_"
    
    static let QUESTION_MARK = "?"

    static let FORWARD_SLASH = "/"
    
    static let TAGS_SEPARATOR = "|"
    
    static let SORTING = "sorting"
    static let GROUPING = "grouping"
    
    static let COLLECTION = "collection"

    struct Titles {
        static let Sorting = "Sorting"
        static let Grouping = "Grouping"
        static let Index = "Index"
    }
    
    static let Sorting_Options_Title = "Sort By"
    static let Grouping_Options_Title = "Group By"
    
    static let Options = "Options"
    
    static let Sorting_Options =  Titles.Sorting + SINGLE_SPACE_STRING + Options
    static let Grouping_Options = Titles.Grouping + SINGLE_SPACE_STRING + Options
    
    static let SETTINGS_VERSION_KEY = "Settings Version"
    static let SETTINGS_VERSION = "2.1"
    
    static let SETTINGS_KEY = "Settings"
    static let VIEW_SPLITS_KEY = "View Splits"
    
    static let SELECTED_SERMON_KEY = "selectedSermonKey"
    static let SELECTED_SERMON_DETAIL_KEY = "selectedSermonDetailKey"
    
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
    
    static let FA_PLAY_PLAUSE_FONT_SIZE = CGFloat(24.0)
    static let FA_PLAY = "\u{f04b}"
    static let FA_PAUSE = "\u{f04c}"
    
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
    
    static let FA_SHOW_FONT_SIZE = CGFloat(24.0)
    static let FA_REORDER = "\u{f0c9}"
    
    static let FA_TAGS_FONT_SIZE = CGFloat(24.0)
    static let FA_TAG = "\u{f02b}"
    static let FA_TAGS = "\u{f02c}"
    
    static let Actions = "Actions"
    
    static let Download = "Download"
    static let Downloaded = Download + "ed"
    static let Downloads = Download + "s"
    static let Downloading = Download + "ing"
    
    static let Audio = "Audio"
    static let Video = "Video"
    
    static let Download_Audio = Download + SINGLE_SPACE_STRING + Audio
    static let Download_Video = Download + SINGLE_SPACE_STRING + Video
    
    static let Download_All = Download  + SINGLE_SPACE_STRING + All
    
    static let Download_All_Audio = Download_All + SINGLE_SPACE_STRING + Audio
    static let Download_All_Video = Download_All + SINGLE_SPACE_STRING + Video
    
    static let Cancel_All = Cancel + SINGLE_SPACE_STRING + All
    static let Delete_All = Delete + SINGLE_SPACE_STRING + All
    
    static let Cancel_All_Downloads = Cancel_All + SINGLE_SPACE_STRING + Downloads
    static let Delete_All_Downloads = Delete_All + SINGLE_SPACE_STRING + Downloads
    
    static let Cancel_All_Audio_Downloads = Cancel_All + SINGLE_SPACE_STRING + Audio + SINGLE_SPACE_STRING + Downloads
    static let Delete_All_Audio_Downloads = Delete_All + SINGLE_SPACE_STRING + Audio + SINGLE_SPACE_STRING + Downloads
    
    static let Cancel_Audio_Download = Cancel + SINGLE_SPACE_STRING + Audio + SINGLE_SPACE_STRING + Download // + QUESTION_MARK
    static let Delete_Audio_Download = Delete + SINGLE_SPACE_STRING + Audio + SINGLE_SPACE_STRING + Download // + QUESTION_MARK
    
    static let Cancel_Video_Download = Cancel + SINGLE_SPACE_STRING + Video + SINGLE_SPACE_STRING + Download // + QUESTION_MARK
    static let Delete_Video_Download = Delete + SINGLE_SPACE_STRING + Video + SINGLE_SPACE_STRING + Download // + QUESTION_MARK
    
    static let Favorites = "Favorites"
    static let Add_to_Favorites = "Add to Favorites"
    static let Remove_From_Favorites = "Remove From Favorites"
    static let Add_All_to_Favorites = "Add All to Favorites"
    static let Remove_All_From_Favorites = "Remove All From Favorites"

    static let FA_SLIDES_SEGMENT_TITLE = FA_SLIDES
    static let FA_TRANSCRIPT_SEGMENT_TITLE = FA_TRANSCRIPT
    static let FA_VIDEO_SEGMENT_TITLE = FA_VIDEO
    
    static let CHECK_FILE_SLEEP_INTERVAL = 0.01
    static let CHECK_FILE_MAX_ITERATIONS = 200
    
    static let SCRIPTURE_URL_PREFIX = "http://www.biblegateway.com/passage/?search="
    static let SCRIPTURE_URL_POSTFIX = "&version=NASB"
    
//    static let TRANSCRIPT_PREFIX = "tx-un-"
    static let PDF_FILE_EXTENSION = ".pdf"
    
    static let New = "New"
    static let All = "All"
    static let None = "None"
    static let Okay = "OK"
    static let Cancel = "Cancel"
    static let Delete = "Delete"
    static let About = "About"
    static let Current_Selection = "Current Selection"
    static let Tags = "Tags"
    
    static let Back = "Back"

    static let Sermon_Playing = "Sermon Playing"
    static let Sermon_Paused = "Sermon Paused"
    
    static let Settings = "Settings"
    
    static let HISTORY = "HISTORY"
    static let History = "History"
    static let Clear_History = "Clear History"
    
    static let Scripture_Index = "Scripture Index"
    
    static let SHOW_LIVE_SEGUE = "Show Live"
    static let SHOW_ABOUT_SEGUE = "Show About"
    static let SHOW_ABOUT2_SEGUE = "Show About2"
    static let SHOW_SERMON_SEGUE = "Show Sermon"
    static let SHOW_SETTINGS_SEGUE = "Show Settings"
    static let SHOW_FULL_SCREEN_SEGUE = "Show Full Screen"
    static let SHOW_INDEX_SERMON_SEGUE = "Show Index Sermon"
    static let SHOW_SCRIPTURE_INDEX_SEGUE = "Show Scripture Index"
    
    static let Print = "Print"
    
    static let Full_Screen = "Full Screen"
    static let Open_in_Browser = "Open in Browser"
    
    static let Email_Sermon = "E-mail"
    static let Email_Series = "E-mail All"
    
    static let Check_for_Update = "Check for Update"
    
    static let Share_on_Facebook = "Share on Facebook"
    static let Share_on_Twitter = "Share on Twitter"

    static let Play = "Play"
    static let Pause = "Pause"
    
    static let Playing = "Playing"
    static let Paused = "Paused"
    
    static let DOWNLOAD_IDENTIFIER = "com.leeke.CBC.download."
    
    static let MP3_FILENAME_EXTENSION = ".mp3"
    static let MP4_FILENAME_EXTENSION = ".mp4"
    static let M3U8_FILENAME_EXTENSION = ".m3u8"
    
    static let TMP_FILENAME_EXTENSION = ".tmp"

    static let CHRONOLOGICAL = "chronological"
    static let Chronological = "Chronological"
    
    static let REVERSE_CHRONOLOGICAL = "reverse chronological"
    static let Reverse_Chronological = "Reverse Chronological"

    static let Newest_to_Oldest = "Newest to Oldest"
    static let Oldest_to_Newest = "Oldest to Newest"
    
    static let sortings = [CHRONOLOGICAL, REVERSE_CHRONOLOGICAL]
    static let Sortings = [Oldest_to_Newest, Newest_to_Oldest]
    
    static let groupings = [Grouping.YEAR, Grouping.TITLE, Grouping.BOOK, Grouping.SPEAKER]
    static let Groupings = [Grouping.Year, Grouping.Title, Grouping.Book, Grouping.Speaker]

    static let Old_Testament = "Old Testament"
    static let New_Testament = "New Testament"
    
    static let OT = "O.T."
    static let NT = "N.T."
    
    static let NOT_IN_THE_BOOKS_OF_THE_BIBLE = Constants.OLD_TESTAMENT_BOOKS.count + Constants.NEW_TESTAMENT_BOOKS.count + 1
    
    static let OLD_TESTAMENT_BOOKS:[String] = [
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
    
    static let OLD_TESTAMENT_CHAPTERS:[Int] = [
        50,
        40,
        27,
        36,
        34,
        24,
        21,
        4,
        31,
        24,
        22,
        25,
        29,
        36,
        10,
        13,
        10,
        42,
        150,
        31,
        12,
        8,
        66,
        52,
        5,
        48,
        12,
        14,
        3,
        9,
        1,
        4,
        7,
        3,
        3,
        3,
        2,
        14,
        4
    ]
    
    static let NEW_TESTAMENT_BOOKS:[String] = [
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
    
    static let NEW_TESTAMENT_CHAPTERS:[Int] = [
        28,
        16,
        24,
        21,
        28,
        16,
        16,
        13,
        6,
        6,
        4,
        4,
        5,
        3,
        6,
        4,
        3,
        1,
        13,
        5,
        5,
        3,
        5,
        1,
        1,
        1,
        22
    ]
}
