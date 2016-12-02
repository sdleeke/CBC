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
    static let m3u8 = "m3u8"
    static let mp4 = "mp4"
    
    static let notes = "transcript"
    static let notes_HTML = "transcript_HTML"
    static let slides = "slides"
    static let outline = "outline"
    
    static let files = "files"

    static let playing = "playing"
    static let showing = "showing"
    
    static let speaker = "teacher" // was "speaker"
    static let speaker_sort = "speaker sort"
    
    static let scripture = "text" // was "scripture"
    static let category = "category"
    
    static let multi_part_name = "multi part name"
    static let multi_part_name_sort = "multi part name sort"

    static let part = "part"
    static let tags = "series"
    static let book = "book"
    static let year = "year"
}

struct MediaType {
    static let AUDIO = "AUDIO"
    static let VIDEO = "VIDEO"
    static let SLIDES = "SLIDES"
    static let NOTES = "NOTES"
    static let OUTLINE = "OUTLINE"
    
    static let NONE = "none"
}

struct Purpose {
    static let audio    = MediaType.AUDIO
    static let video    = MediaType.VIDEO
    static let slides   = MediaType.SLIDES
    static let notes    = MediaType.NOTES
    static let outline  = MediaType.OUTLINE
}

struct Playing {
    static let audio    = MediaType.AUDIO
    static let video    = MediaType.VIDEO
}

struct Showing {
    static let video    = MediaType.VIDEO
    static let notes    = MediaType.NOTES
    static let slides   = MediaType.SLIDES
    static let none     = MediaType.NONE
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
    struct JSON {
        static let MEDIA_PATH = "media" //
        
        static let CATEGORIES_PATH = "categories" //

        struct URL {
            static let BASE = "http://countrysidebible.org/mediafeed.php?return=" // "http://dev.countrysidebible.org/medialist_all.php?return="
            
            static let MEDIA = BASE + MEDIA_PATH //
            
            static let CATEGORIES = BASE + CATEGORIES_PATH //
            
            static let CATEGORY = MEDIA + "&categoryID=" //
            
            static let CATEGORY_MEDIA = CATEGORY + globals.mediaCategory.selectedID! //
            
            static let SINGLE = BASE + "single&mediacode="
        }

        struct ARRAY_KEY {
            static let CATEGORY_ENTRIES = "categoryEntries"
            static let MEDIA_ENTRIES    = "mediaEntries"
            static let SINGLE_ENTRY     = "singleEntry"
        }
        
        static let TYPE = "json"
        static let FILENAME_EXTENSION = ".json"
        
        struct FILENAME {
            static let CATEGORIES = ARRAY_KEY.CATEGORY_ENTRIES + FILENAME_EXTENSION
            static let MEDIA      = ARRAY_KEY.MEDIA_ENTRIES + FILENAME_EXTENSION
        }
    }

    struct BASE_URL {
        static let MEDIA = "http://media.countrysidebible.org/"
        
        static let VIDEO_PREFIX = "https://player.vimeo.com/external/"
        
        static let EXTERNAL_VIDEO_PREFIX = "https://vimeo.com/"
        
        //    Slides: {year}/{mediacode}slides.pdf
        //    Outline: {year}/{mediacode}outline.pdf
        //    Transcript: {year}/{mediacode}transcript.pdf
    }
    
    struct URL {
        static let LIVE_STREAM = "https://content.uplynk.com/channel/bd25cb880ed84b4db3061b9ad16b5a3c.m3u8"
        
        static let REACHABILITY_TEST = "http://www.countrysidebible.org/"
    }

    struct NOTIFICATION {
        static let UPDATE_PLAY_PAUSE        = "UPDATE PLAY PAUSE"
        
        static let READY_TO_PLAY            = "READY TO PLAY"
        static let FAILED_TO_PLAY           = "FAILED TO PLAY"
        
        static let SHOW_PLAYING             = "SHOW PLAYING"
        
        static let PAUSED                   = "PAUSED"
        
        static let UPDATE_VIEW              = "UPDATE VIEW"
        static let CLEAR_VIEW               = "CLEAR VIEW"
        
        static let MEDIA_UPDATE_CELL        = "MEDIA UPDATE CELL"
        
        static let MEDIA_UPDATE_UI          = "MEDIA UPDATE UI"
        static let MEDIA_DOWNLOAD_FAILED    = "MEDIA DOWNLOAD FAILED"
        
        static let UPDATE_MEDIA_LIST        = "UPDATE MEDIA LIST"
        
        static let EDITING                  = "EDITING"
        static let NOT_EDITING              = "NOT EDITING"
    }
    
    struct IDENTIFIER {
        static let POPOVER_CELL             = "PopoverCell"
        static let POPOVER_TABLEVIEW        = "PopoverTableView"
        
        static let WEB_VIEW                 = "Web View"
        
        static let MEDIAITEM                = "MediaItem"
        static let MULTIPART_MEDIAITEM      = "MultiPartMediaItem"
        
        static let STRING_PICKER            = "String Picker"
        static let SCRIPTURE_INDEX          = "Scripture Index"
        
        static let INDEX_MEDIA_ITEM         = "IndexMediaItem"
        
        static let SHOW_MEDIAITEM_NAVCON    = "Show MediaItem NavCon"
        static let SHOW_MEDIAITEM           = "Show MediaItem"
    }
    
    struct TIMER_INTERVAL {
        static let SLIDER       = 0.1
        static let PLAYER       = 0.1
        static let DOWNLOADING  = 0.2
        static let LOADING      = 0.2
        static let PROGRESS     = 0.1
        static let WORKING      = 0.1
        static let SEEKING      = 0.1
    }
    
    static let MIN_PLAY_TIME = 15.0
    static let MIN_LOAD_TIME = 30.0
    
    static let BACK_UP_TIME  = 1.5
    
    struct CBC {
        static let EMAIL = "cbcstaff@countrysidebible.org"
        static let WEBSITE = "http://www.countrysidebible.org"
        static let MEDIA_WEBSITE = WEBSITE + "/cbcmedia"
        static let SINGLE_WEBSITE = MEDIA_WEBSITE + "?return=single&mediacode="
        static let STREET_ADDRESS = "250 Countryside Court"
        static let CITY_STATE_ZIPCODE_COUNTRY = "Southlake, TX 76092, USA"
        static let PHONE_NUMBER = "(817) 488-5381"
        static let FULL_ADDRESS = STREET_ADDRESS + ", " + CITY_STATE_ZIPCODE_COUNTRY
        
        static let SHORT = "CBC"
        static let LONG = "Countryside Bible Church"
        
        struct TITLE {
            static let POSTFIX  = SINGLE_SPACE + Media
            
            static let SHORT    = CBC.SHORT + POSTFIX
            static let LONG     = CBC.LONG + POSTFIX
        }
    }
    
    struct SCRIPTURE_URL {
        static let PREFIX = "https://www.biblegateway.com/passage/?search="
        static let POSTFIX = "&version=NASB"
    }
    
    static let SEARCH_RESULTS_BETWEEN_UPDATES = 100
    
    static let DICT = "dict"

    static let PART_INDICATOR_SINGULAR = " (Part "
    
    static let VIEW_SPLIT = "VIEW SPLIT"
    static let SLIDE_SPLIT = "SLIDE SPLIT"
    
    struct Title {
        static let Downloading_Media    = "Downloading Media"
        static let Loading_Media        = "Loading Media"
        static let Synthesizing_Tags    = "Synthesizing Tags"
        static let Loading_Settings     = "Loading Settings"
        static let Sorting_and_Grouping = "Sorting and Grouping"
        static let Setting_up_Player    = "Setting up Player"
    }
    
    static let COVER_ART_IMAGE = "cover170x170"
    
//    struct CACHE {
//        static let POLICY = NSURLRequest.CachePolicy.reloadRevalidatingCacheData
//        static let TIMEOUT = 10.0
//    }

    static let HEADER_HEIGHT = CGFloat(48)
    static let VIEW_TRANSITION_TIME = 0.75 // seconds
    
    static let PLAY_OBSERVER_TIME_INTERVAL = 10.0 // seconds

    static let SKIP_TIME_INTERVAL = 15
    static let ZERO = "0"

    static let MEDIA_CATEGORY = "MEDIA CATEGORY"
    
    static let SEARCH_TEXT = "SEARCH TEXT"
    
    static let Live = "Live"
    
    static let CONTENT_OFFSET_X_RATIO = "ContentOffsetXRatio"
    static let CONTENT_OFFSET_Y_RATIO = "ContentOffsetYRatio"
    
    static let ZOOM_SCALE = "ZoomScale"
    
    static let Email_CBC = "E-mail " + CBC.SHORT
    static let CBC_WebSite = CBC.SHORT + " Website"
    static let CBC_in_Apple_Maps = CBC.SHORT + " in Apple Maps"
    static let CBC_in_Google_Maps = CBC.SHORT + " in Google Maps"

    static let Show = "Show"
    static let Select_Category = "Select Category"
    
    static let Search = "Search"
    static let Tokens = "Words"

//    static let Search_Terms = "Search Terms"
//    static let Search_Transcript = "Search Transcript"
    
    static let Sermon = "Sermon"
    static let Sermons = "Sermons"
    
    static let Transcript = "Transcript"
    
    static let EMAIL_SUBJECT = CBC.LONG
    static let EMAIL_ONE_SUBJECT = CBC.LONG + " Media"
    static let EMAIL_ALL_SUBJECT = EMAIL_ONE_SUBJECT
    
    static let Network_Error = "Network Error"
    static let Content_Failed_to_Load = "Content Failed to Load"
    
    static let TAGGED = "tagged"
    static let ALL = "all"
    static let DOWNLOADED = "downloaded"

//    static let Scripture_Full_Screen = "Scripture Full Screen"
    static let Scripture_in_Browser = "Scripture in Browser"
    
    static let EMPTY_STRING = ""

    static let QUOTE = "\""
    static let PLUS = "+"

    static let SINGLE_SPACE = " "
    static let SINGLE_UNDERSCORE = "_"
    
    static let QUESTION_MARK = "?"

    static let FORWARD_SLASH = "/"
    
    static let TAGS_SEPARATOR = "|"
    
    struct Menu {
        static let Sorting = "Sorting"
        static let Grouping = "Grouping"
        static let Index = "Index"
    }
    
    struct Options_Title {
        static let Sorting = "Sort By"
        static let Grouping = "Group By"
    }
    
    static let Options = "Options"
    
    static let Sorting_Options =  Menu.Sorting + SINGLE_SPACE + Options
    static let Grouping_Options = Menu.Grouping + SINGLE_SPACE + Options
    
    static let Settings = "Settings"
    
    struct USER_SETTINGS {
        static let SEARCH_TRANSCRIPTS = "SEARCH TRANSCRIPTS"
        static let AUTO_ADVANCE = "AUTO_ADVANCE"
        static let CACHE_DOWNLOADS = "CACHE DOWNLOADS"
    }

    struct SETTINGS {
        static let MEDIA_PLAYING = "media playing"
        static let CURRENT_TIME = "current time"
        
        static let AT_END = "at end"
        
        static let prefix = "settings:"
        
        struct VERSION {
            static let KEY = prefix + " Version"
            static let NUMBER = "2.8"
        }
        
        struct KEY {
            static let SORTING  = prefix + "sorting"
            static let GROUPING = prefix + "grouping"
            
            static let COLLECTION = prefix + "collection"

            static let CATEGORY         = prefix + "category"
            static let MEDIA            = prefix + "media"
            static let MULTI_PART_MEDIA = prefix + "multiPart media"
            
            struct SELECTED_MEDIA {
                static let MASTER   = prefix + "selected master"
                static let DETAIL   = prefix + "selected detail"
            }
        }
    }
    
    static let MIN_SLIDER_WIDTH         = CGFloat(60)
    static let MIN_STV_SEGMENT_WIDTH    = CGFloat(25)
    
    static let Selected_Scriptures  = "Selected Scriptures"

    static let Individual_Media     = "Single Part Media"
    
    struct AV_SEGMENT_INDEX {
        static let AUDIO = 0
        static let VIDEO = 1
    }
    
    static let AUDIO_VIDEO_MAX_WIDTH = CGFloat(50)
    
    // first.service < second.service relies upon the face that AM and PM are alphabetically sorted the same way they are related chronologically, i.e. AM comes before PM in both cases.
    struct SERVICE {
        static let MORNING = "AM"
        static let EVENING = "PM"
    }

    struct FA {
        static let name = "FontAwesome"
        
        static let PLAY_PLAUSE_FONT_SIZE = CGFloat(24.0)
        static let PLAY = "\u{f04b}"
        static let PAUSE = "\u{f04c}"

        static let PLAYING = "\u{f028}"

        static let ICONS_FONT_SIZE = CGFloat(12.0)
        static let SLIDES = "\u{f022}"
        static let TRANSCRIPT = "\u{f0f6}"
        static let AUDIO = "\u{f025}"
        static let VIDEO = "\u{f03d}"
        
        static let DOWNLOAD_FONT_SIZE = CGFloat(18.0)
        static let DOWNLOAD = "\u{f019}"
        static let DOWNLOADING = "\u{f0ae}"
        static let DOWNLOADED = "\u{f1c7}"
        static let CLOUD_DOWNLOAD = "\u{f0ed}"
        
        static let SHOW_FONT_SIZE = CGFloat(24.0)
        static let REORDER = "\u{f0c9}"
        
        static let TAGS_FONT_SIZE = CGFloat(24.0)
        static let TAG = "\u{f02b}"
        static let TAGS = "\u{f02c}"
    }

    struct STV_SEGMENT_TITLE {
        static let SLIDES       = FA.SLIDES
        static let TRANSCRIPT   = FA.TRANSCRIPT
        static let VIDEO        = FA.VIDEO
    }

    static let Actions = "Actions"
    
    static let Download = "Download"
    static let Downloaded = Download + "ed"
    static let Downloads = Download + "s"
    static let Downloading = Download + "ing"
    
    static let Audio = "Audio"
    static let Video = "Video"
    
    static let Download_Audio = Download + SINGLE_SPACE + Audio
    static let Download_Video = Download + SINGLE_SPACE + Video
    
    static let Download_All = Download  + SINGLE_SPACE + All
    
    static let Download_All_Audio = Download_All + SINGLE_SPACE + Audio
    static let Download_All_Video = Download_All + SINGLE_SPACE + Video
    
    static let Cancel_All = Cancel + SINGLE_SPACE + All
    static let Delete_All = Delete + SINGLE_SPACE + All
    
    static let Cancel_All_Downloads = Cancel_All + SINGLE_SPACE + Downloads
    static let Delete_All_Downloads = Delete_All + SINGLE_SPACE + Downloads
    
    static let Cancel_All_Audio_Downloads = Cancel_All + SINGLE_SPACE + Audio + SINGLE_SPACE + Downloads
    static let Delete_All_Audio_Downloads = Delete_All + SINGLE_SPACE + Audio + SINGLE_SPACE + Downloads
    
    static let Cancel_Audio_Download = Cancel + SINGLE_SPACE + Audio + SINGLE_SPACE + Download // + QUESTION_MARK
    static let Delete_Audio_Download = Delete + SINGLE_SPACE + Audio + SINGLE_SPACE + Download // + QUESTION_MARK
    
    static let Cancel_Video_Download = Cancel + SINGLE_SPACE + Video + SINGLE_SPACE + Download // + QUESTION_MARK
    static let Delete_Video_Download = Delete + SINGLE_SPACE + Video + SINGLE_SPACE + Download // + QUESTION_MARK
    
    static let Add_to = "Add to"
    static let Remove_From = "Remove From"
    static let Add_All_to = "Add All to"
    static let Remove_All_From = "Remove All From"

    static let Favorites = "Favorites"
    static let Add_to_Favorites = Add_to + SINGLE_SPACE + Favorites
    static let Remove_From_Favorites = Remove_From + SINGLE_SPACE + Favorites
    static let Add_All_to_Favorites = Add_All_to + SINGLE_SPACE + Favorites
    static let Remove_All_From_Favorites = Remove_All_From + SINGLE_SPACE + Favorites

    static let CHECK_FILE_SLEEP_INTERVAL = 0.01
    static let CHECK_FILE_MAX_ITERATIONS = 200
    
//    static let TRANSCRIPT_PREFIX = "tx-un-"
    
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

    static let Media = "Media"
    static let Media_Playing = Media + SINGLE_SPACE + Playing
    static let Media_Paused = Media + SINGLE_SPACE + Paused
    
    static let HISTORY = "HISTORY"
    static let History = "History"
    static let Clear_History = "Clear History"
    
    static let Scripture_Index = "Scripture Index"
    
    struct SEGUE {
        static let SHOW_LIVE                = "Show Live"
        static let SHOW_ABOUT               = "Show About"
        static let SHOW_ABOUT2              = "Show About2"
        static let SHOW_MEDIAITEM           = "Show MediaItem"
        static let SHOW_SETTINGS            = "Show Settings"
        static let SHOW_FULL_SCREEN         = "Show Full Screen"
        static let SHOW_INDEX_MEDIAITEM     = "Show Index MediaItem"
        static let SHOW_SCRIPTURE_INDEX     = "Show Scripture Index"
    }
    
    static let Print = "Print"
    static let Print_All = "Print All"
 
    static let Print_Slides = "Print Slides"
    static let Print_Transcript = "Print Transcript"
    
    static let Zoom = "Zoom"
    static let Full_Screen = "Full Screen"
    static let Open_in_Browser = "Open in Browser"
    
    static let Open_on_CBC_Website = "Open on CBC Web Site"
    
    static let Email_One = "E-mail"
    static let Email_All = "E-mail All"
    
    static let Increase_Font_Size = "Increase Font Size"
    static let Decrease_Font_Size = "Decrease Font Size"
    
    static let Refresh_Document = "Refresh Document"
    
    static let Share = "Share"
    static let Share_All = "Share All"
    
    static let Share_on = "Share on "
    static let Share_on_Facebook = Share_on + "Facebook"
    static let Share_on_Twitter = Share_on + "Twitter"

    static let Play = "Play"
    static let Pause = "Pause"
    
    static let Playing = "Playing"
    static let Paused = "Paused"
    
    static let CMTime_Resolution = Int32(1000)
    
    static let APP_ID = "org.countrysidebible.CBC"
    
    static let DOWNLOAD_IDENTIFIER = APP_ID + ".download."
    
    struct FILENAME_EXTENSION {
        static let MP3  = ".mp3"
        static let MP4  = ".mp4"
        static let M3U8 = ".m3u8"
        static let TMP  = ".tmp"
        static let PDF  = ".pdf"
    }

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

    struct SCRIPTURE_INDEX {
        static let BASE         = "SCRIPTURE INDEX"
        static let TESTAMENT    = BASE + " TESTAMENT"
        static let BOOK         = BASE + " BOOK"
        static let CHAPTER      = BASE + " CHAPTER"
        static let VERSE        = BASE + " VERSE"
    }
    
    static let Old_Testament = "Old Testament"
    static let New_Testament = "New Testament"
    
    static let Testaments = [Old_Testament,New_Testament]
    
    static let OT = "O.T."
    static let NT = "N.T."
    
    static let TESTAMENTS = [OT,NT]
    
    static let BOOKS = [OT:OLD_TESTAMENT_BOOKS,NT:NEW_TESTAMENT_BOOKS]
    
    static let CHAPTERS = [OT:OLD_TESTAMENT_CHAPTERS,NT:NEW_TESTAMENT_CHAPTERS]
    
    static let NOT_IN_THE_BOOKS_OF_THE_BIBLE = Constants.OLD_TESTAMENT_BOOKS.count + Constants.NEW_TESTAMENT_BOOKS.count + 1
    
    static let NO_CHAPTER_BOOKS = ["Philemon","Jude","2 John","3 John"]

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
    
    static let OLD_TESTAMENT_VERSES:[[Int]] = [
[31,25,24,26,32,22,24,22,29,32,32,20,18,24,21,16,27,33,38,18,34,24,20,67,34,35,46,22,35,43,54,33,20,31,29,43,36,30,23,23,57,38,34,34,28,34,31,22,33,26],
[22,25,22,31,23,30,29,28,35,29,10,51,22,31,27,36,16,27,25,26,37,30,33,18,40,37,21,43,46,38,18,35,23,35,35,38,29,31,43,38],
[17,16,17,35,26,23,38,36,24,20,47,8,59,57,33,34,16,30,37,27,24,33,44,23,55,46,34],
[54,34,51,49,31,27,89,26,23,36,35,16,33,45,41,35,28,32,22,29,35,41,30,25,19,65,23,31,39,17,54,42,56,29,34,13],
[46,37,29,49,33,25,26,20,29,22,32,31,19,29,23,22,20,22,21,20,23,29,26,22,19,19,26,69,28,20,30,52,29,12],
[18,24,17,24,15,27,26,35,27,43,23,24,33,15,63,10,18,28,51,9,45,34,16,33],
[36,23,31,24,31,40,25,35,57,18,40,15,25,20,20,31,13,31,30,48,25],
[22,23,18,22],
[28,36,21,22,12,21,17,22,27,27,15,25,23,52,35,23,58,30,24,42,16,23,28,23,43,25,12,25,11,31,13],
[27,32,39,12,25,23,29,18,13,19,27,31,39,33,37,23,29,32,44,26,22,51,39,25],
[53,46,28,20,32,38,51,66,28,29,43,33,34,31,34,34,24,46,21,43,29,54],
[18,25,27,44,27,33,20,29,37,36,20,22,25,29,38,20,41,37,37,21,26,20,37,20,30],
[54,55,24,43,41,66,40,40,44,14,47,41,14,17,29,43,27,17,19,8,30,19,32,31,31,32,34,21,30],
[18,17,17,22,14,42,22,18,31,19,23,16,23,14,19,14,19,34,11,37,20,12,21,27,28,23,9,27,36,27,21,33,25,33,26,23],
[11,70,13,24,17,22,28,36,15,44],
[11,20,38,17,19,19,72,18,37,40,36,47,31],
[22,23,15,17,14,14,10,17,32,3,17,8,30,16,24,10],
[22,13,26,21,27,30,21,22,35,22,20,25,28,22,35,22,16,21,29,29,34,30,17,25,6,14,23,28,25,31,40,22,33,37,16,33,24,41,30,32,26,17],
[6,11,9,9,13,11,18,10,21,18,7,9,6,7,5,11,15,51,15,10,14,32,6,10,22,11,14,9,11,13,25,11,22,23,28,13,40,23,14,18,14,12,5,27,18,12,10,15,21,23,21,11,7,9,24,14,12,12,18,14,9,13,12,11,14,20,8,36,37,6,24,20,28,23,11,13,21,72,13,20,17,8,19,13,14,17,7,19,53,17,16,16,5,23,11,13,12,9,9,5,8,29,22,35,45,48,43,14,31,7,10,10,9,8,18,19,2,29,176,7,8,9,4,8,5,6,5,6,8,8,3,18,3,3,21,26,9,8,24,14,10,8,12,15,21,10,20,14,9,6],
[33,22,35,27,23,35,27,36,18,32,31,28,25,35,33,33,28,24,29,30,31,29,35,34,28,28,27,28,27,33,31],
[18,26,22,17,19,12,29,17,18,20,10,14],
[17,17,11,16,16,12,14,14],
[31,22,26,6,30,13,25,23,20,34,16,6,22,32,9,14,14,7,25,6,17,25,18,23,12,21,13,29,24,33,9,20,24,17,10,22,38,22,8,31,29,25,28,28,25,13,15,22,26,11,23,15,12,17,13,12,21,14,21,22,11,12,19,11,25,24],
[19,37,25,31,31,30,34,23,25,25,23,17,27,22,21,21,27,23,15,18,14,30,40,10,38,24,22,17,32,24,40,44,26,22,19,32,21,28,18,16,18,22,13,30,5,28,7,47,39,46,64,34],
[22,22,66,22,22],
[28,10,27,17,17,14,27,18,11,22,25,28,23,23,8,63,24,32,14,44,37,31,49,27,17,21,36,26,21,26,18,32,33,31,15,38,28,23,29,49,26,20,27,31,25,24,23,35],
[21,49,100,34,30,29,28,27,27,21,45,13,64,42],
[9,25,5,19,15,11,16,14,17,15,11,15,15,10],
[20,27,5,21],
[15,16,15,13,27,14,17,14,15],
[21],
[16,11,10,11],
[16,13,12,14,14,16,20],
[14,14,19],
[17,20,19],
[18,15,20],
[15,23],
[17,17,10,14,11,15,14,23,17,12,17,14,9,21],
[14,17,18,6]
    ]
    
    static let NEW_TESTAMENT_VERSES:[[Int]] = [
[25,23,17,25,48,34,29,34,38,42,30,50,58,36,39,28,27,35,30,34,46,46,39,51,46,75,66,20],
[45,28,35,41,43,56,37,38,50,52,33,44,37,72,47,20],
[80,52,38,44,39,49,50,56,62,42,54,59,35,35,32,31,37,43,48,47,38,71,56,53],
[51,25,36,54,47,71,53,59,41,42,57,50,38,31,27,33,26,40,42,31,25],
[26,47,26,37,42,15,60,40,43,48,30,25,52,28,41,40,34,28,40,38,40,30,35,27,27,32,44,31],
[32,29,31,25,21,23,25,39,33,21,36,21,14,23,33,27],
[31,16,23,21,13,20,40,13,27,33,34,31,13,40,58,24],
[24,17,18,18,21,18,16,24,15,18,33,21,13],
[24,21,29,31,26,18],
[23,22,21,32,33,24],
[30,30,21,23],
[29,23,25,18],
[10,20,13,18,28],
[12,17,18],
[20,15,16,16,25,21],
[18,26,17,22],
[16,15,15],
[25],
[14,18,19,16,14,20,28,13,28,39,40,29,25],
[27,26,18,17,20],
[25,25,22,19,14],
[21,22,18],
[10,29,24,21,21],
[13],
[15],
[25],
[20,29,22,11,14,17,17,13,21,11,19,17,18,20,8,21,18,24,21,15,27,21]
    ]
}
