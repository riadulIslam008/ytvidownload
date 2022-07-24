// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'single_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SingleTrack _$SingleTrackFromJson(Map<String, dynamic> json) => SingleTrack(
      json['id'] as int,
      json['path'] as String,
      json['title'] as String,
      json['size'] as String,
      json['totalSize'] as int,
      $enumDecodeNullable(_$StreamTypeEnumMap, json['streamType']) ??
          StreamType.video,
    )
      ..downloadPerc = json['downloadPerc'] as int
      ..downloadStatus =
          $enumDecode(_$DownloadStatusEnumMap, json['downloadStatus'])
      ..downloadedBytes = json['downloadedBytes'] as int
      ..error = json['error'] as String;

Map<String, dynamic> _$SingleTrackToJson(SingleTrack instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'size': instance.size,
      'totalSize': instance.totalSize,
      'streamType': _$StreamTypeEnumMap[instance.streamType],
      'path': instance.path,
      'downloadPerc': instance.downloadPerc,
      'downloadStatus': _$DownloadStatusEnumMap[instance.downloadStatus],
      'downloadedBytes': instance.downloadedBytes,
      'error': instance.error,
    };

const _$StreamTypeEnumMap = {
  StreamType.audio: 'audio',
  StreamType.video: 'video',
};

const _$DownloadStatusEnumMap = {
  DownloadStatus.downloading: 'downloading',
  DownloadStatus.success: 'success',
  DownloadStatus.failed: 'failed',
  DownloadStatus.muxing: 'muxing',
  DownloadStatus.canceled: 'canceled',
};
