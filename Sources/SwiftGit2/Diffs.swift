//
//  Diffs.swift
//  SwiftGit2
//
//  Created by Jake Van Alstyne on 8/20/17.
//  Copyright © 2017 GitHub, Inc. All rights reserved.
//

import Clibgit2

public struct StatusEntry {
	public var status: Diff.Status
	public var headToIndex: Diff.Delta?
	public var indexToWorkDir: Diff.Delta?

	public init(from statusEntry: git_status_entry) {
		self.status = Diff.Status(rawValue: statusEntry.status.rawValue)

		if let htoi = statusEntry.head_to_index {
			self.headToIndex = Diff.Delta(htoi.pointee)
		}

		if let itow = statusEntry.index_to_workdir {
			self.indexToWorkDir = Diff.Delta(itow.pointee)
		}
	}
}

public struct Diff {

	/// The set of deltas.
	public var deltas = [Delta]()

	public struct Delta {
		public static let type = GIT_OBJECT_REF_DELTA

		public var status: Status
		public var flags: Flags
		public var oldFile: File?
		public var newFile: File?

		public init(_ delta: git_diff_delta) {
            let char = git_diff_status_char(delta.status)
            print("DEBUG: Status raw is \(delta.status)")
            print("DEBUG: Char status is \(char)")
            print("DEBUG: GIT_DELTA_MODIFIED is \(GIT_DELTA_MODIFIED.rawValue)")
            print("DEBUG: STATUS is \(Status(rawValue: delta.status.rawValue))")
            
            switch char {
            case 63:
                self.status = Status.untracked
            case 65:
                self.status = Status.added
            case 67:
                self.status = Status.copied
            case 68:
                self.status = Status.deleted
            case 73:
                self.status = Status.ignored
            case 77:
                self.status = Status.modified
            case 82:
                self.status = Status.renamed
            case 84:
                self.status = Status.typeChange
            case 88:
                self.status = Status.unreadable
            default:
                self.status = Status.none
            }
			self.flags = Flags(rawValue: delta.flags)
			self.oldFile = File(delta.old_file)
			self.newFile = File(delta.new_file)
		}
	}

	public struct File {
		public var oid: OID
		public var path: String
		public var size: UInt64
		public var flags: Flags

		public init(_ diffFile: git_diff_file) {
			self.oid = OID(diffFile.id)
			let path = diffFile.path
			self.path = path.map(String.init(cString:))!
			self.size = diffFile.size
			self.flags = Flags(rawValue: diffFile.flags)
		}
	}

	public struct Status: OptionSet {
		// This appears to be necessary due to bug in Swift
		// https://bugs.swift.org/browse/SR-3003
		public init(rawValue: UInt32) {
			self.rawValue = rawValue
		}
		public let rawValue: UInt32

        public static let none     = Status([])
		public static let unmodified     = Status(rawValue: GIT_DELTA_UNMODIFIED.rawValue)
		public static let added          = Status(rawValue: GIT_DELTA_ADDED.rawValue)
		public static let deleted        = Status(rawValue: GIT_DELTA_DELETED.rawValue)
		public static let modified       = Status(rawValue: GIT_DELTA_MODIFIED.rawValue)
		public static let renamed        = Status(rawValue: GIT_DELTA_RENAMED.rawValue)
		public static let copied         = Status(rawValue: GIT_DELTA_COPIED.rawValue)
		public static let ignored        = Status(rawValue: GIT_DELTA_IGNORED.rawValue)
		public static let untracked      = Status(rawValue: GIT_DELTA_UNTRACKED.rawValue)
		public static let typeChange     = Status(rawValue: GIT_DELTA_TYPECHANGE.rawValue)
		public static let unreadable     = Status(rawValue: GIT_DELTA_UNREADABLE.rawValue)
	}

	public struct Flags: OptionSet {
		// This appears to be necessary due to bug in Swift
		// https://bugs.swift.org/browse/SR-3003
		public init(rawValue: UInt32) {
			self.rawValue = rawValue
		}
		public let rawValue: UInt32

		public static let binary     = Flags([])
		public static let notBinary  = Flags(rawValue: 1 << 0)
		public static let validId    = Flags(rawValue: 1 << 1)
		public static let exists     = Flags(rawValue: 1 << 2)
	}

	/// Create an instance with a libgit2 `git_diff`.
	public init(_ pointer: OpaquePointer) {
		for i in 0..<git_diff_num_deltas(pointer) {
			if let delta = git_diff_get_delta(pointer, i) {
				deltas.append(Diff.Delta(delta.pointee))
			}
		}
	}
}
