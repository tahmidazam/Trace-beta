# Document lifecycle

Understand Trace document file creation and writing to disk.

## Overview

A file type should strive to be minimal to be space-efficient on disk and require little overhead to create an instance from raw file data. The structure ``TraceDocument`` represents the Trace file type, `.trace` and governs the lifecycle of a trace document.

## Balancing space-efficiency and property convenience

The ``TraceDocumentContents`` structure has property types that are more convenient to manipulate, specifically the property ``TraceDocumentContents/streams`` which has type ``Stream``. This is relative to a dictionary of keys representing electrodes and values representing samples. However the latter is more space efficient as JSON, and is found in ``CompressedTraceDocumentContents``. ``TraceDocumentContents`` can be converted into ``CompressedTraceDocumentContents`` through its initialiser, and ``CompressedTraceDocumentContents`` can be turned into ``TraceDocumentContents`` through the computed property ``CompressedTraceDocumentContents/uncompressed()``. The contents is held in the ``TraceDocument`` as ``TraceDocumentContents`` when a file is open, but is compressed to ``CompressedTraceDocumentContents`` for writing to disk.

## Lifecycle components

When a file is opened, it is either new or pre-existing:
- Opening new files: file creation is managed by SwiftUI's DocumentGroup (which is intialised in ``TraceApp/body``), which passes a new document into ``DocumentView`` as a binding ``TraceDocument`` after intialisation through ``TraceDocument/init(trace:)``. An empty Trace document has an empty array for its samples array and a sample rate of `200` Hz as default.
- Opening pre-existing files: SwiftUI's DocumentGroup also passes through a ``TraceDocument`` instance when the scene opens a pre-existing file after initialisation through ``TraceDocument/init(configuration:)``. The read configuration contains the file contents as raw data, which is then decoded into an instance of ``CompressedTraceDocumentContents`` from JSON. The instance is then uncompressed by ``CompressedTraceDocumentContents/uncompressed()``.

The ``TraceDocument/fileWrapper(configuration:)`` function governs saving of the file to disk. A ``CompressedTraceDocumentContents`` is initialised from a snapshot of the ``TraceDocumentContents`` held by ``TraceDocument/contents`` and then encoded to JSON and saved through a file wrapper.
 
## Topics

### Relevant structures

- ``TraceDocument``
- ``TraceDocumentContents``
- ``CompressedTraceDocumentContents``
