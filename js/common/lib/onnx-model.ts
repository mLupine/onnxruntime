// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License.

// #region File type declarations

/**
 * A string that represents a file's URL.
 */
export type FileUrl = string;

/**
 * A string that represents a file's path.
 *
 * Available only in onnxruntime-node or onnxruntime-web running in Node.js.
 */
export type FilePath = string;

/**
 * A Blob object that represents a file.
 */
export type FileBlob = Blob;

/**
 * A Uint8Array, ArrayBuffer or SharedArrayBuffer object that represents a file content.
 *
 * When it is an ArrayBuffer or SharedArrayBuffer, the whole buffer is assumed to be the file content.
 */
export type FileData = Uint8Array|ArrayBufferLike;

/**
 * Represents a file that can be loaded by the ONNX Runtime JavaScript API.
 */
export type FileType = FileUrl|FilePath|FileBlob|FileData;

/**
 * A tuple that represents a file with its checksum.
 */
export type FileWithChecksumType = [file: FileType, checksum: string];

// #endregion File type declarations
