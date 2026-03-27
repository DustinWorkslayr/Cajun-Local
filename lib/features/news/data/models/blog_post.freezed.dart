// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'blog_post.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BlogPost {

 String get id; String get slug; String get title; String get status; String? get content; String? get excerpt;@JsonKey(name: 'author_id') String? get authorId;@JsonKey(name: 'cover_image_url') String? get coverImageUrl;@JsonKey(name: 'parish_ids') List<String>? get parishIds;@JsonKey(name: 'published_at') DateTime? get publishedAt;@JsonKey(name: 'created_at') DateTime? get createdAt;@JsonKey(name: 'updated_at') DateTime? get updatedAt;
/// Create a copy of BlogPost
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BlogPostCopyWith<BlogPost> get copyWith => _$BlogPostCopyWithImpl<BlogPost>(this as BlogPost, _$identity);

  /// Serializes this BlogPost to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BlogPost&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.content, content) || other.content == content)&&(identical(other.excerpt, excerpt) || other.excerpt == excerpt)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.coverImageUrl, coverImageUrl) || other.coverImageUrl == coverImageUrl)&&const DeepCollectionEquality().equals(other.parishIds, parishIds)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,title,status,content,excerpt,authorId,coverImageUrl,const DeepCollectionEquality().hash(parishIds),publishedAt,createdAt,updatedAt);

@override
String toString() {
  return 'BlogPost(id: $id, slug: $slug, title: $title, status: $status, content: $content, excerpt: $excerpt, authorId: $authorId, coverImageUrl: $coverImageUrl, parishIds: $parishIds, publishedAt: $publishedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $BlogPostCopyWith<$Res>  {
  factory $BlogPostCopyWith(BlogPost value, $Res Function(BlogPost) _then) = _$BlogPostCopyWithImpl;
@useResult
$Res call({
 String id, String slug, String title, String status, String? content, String? excerpt,@JsonKey(name: 'author_id') String? authorId,@JsonKey(name: 'cover_image_url') String? coverImageUrl,@JsonKey(name: 'parish_ids') List<String>? parishIds,@JsonKey(name: 'published_at') DateTime? publishedAt,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class _$BlogPostCopyWithImpl<$Res>
    implements $BlogPostCopyWith<$Res> {
  _$BlogPostCopyWithImpl(this._self, this._then);

  final BlogPost _self;
  final $Res Function(BlogPost) _then;

/// Create a copy of BlogPost
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? slug = null,Object? title = null,Object? status = null,Object? content = freezed,Object? excerpt = freezed,Object? authorId = freezed,Object? coverImageUrl = freezed,Object? parishIds = freezed,Object? publishedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,excerpt: freezed == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as String?,authorId: freezed == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String?,coverImageUrl: freezed == coverImageUrl ? _self.coverImageUrl : coverImageUrl // ignore: cast_nullable_to_non_nullable
as String?,parishIds: freezed == parishIds ? _self.parishIds : parishIds // ignore: cast_nullable_to_non_nullable
as List<String>?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [BlogPost].
extension BlogPostPatterns on BlogPost {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BlogPost value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BlogPost() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BlogPost value)  $default,){
final _that = this;
switch (_that) {
case _BlogPost():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BlogPost value)?  $default,){
final _that = this;
switch (_that) {
case _BlogPost() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String slug,  String title,  String status,  String? content,  String? excerpt, @JsonKey(name: 'author_id')  String? authorId, @JsonKey(name: 'cover_image_url')  String? coverImageUrl, @JsonKey(name: 'parish_ids')  List<String>? parishIds, @JsonKey(name: 'published_at')  DateTime? publishedAt, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BlogPost() when $default != null:
return $default(_that.id,_that.slug,_that.title,_that.status,_that.content,_that.excerpt,_that.authorId,_that.coverImageUrl,_that.parishIds,_that.publishedAt,_that.createdAt,_that.updatedAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String slug,  String title,  String status,  String? content,  String? excerpt, @JsonKey(name: 'author_id')  String? authorId, @JsonKey(name: 'cover_image_url')  String? coverImageUrl, @JsonKey(name: 'parish_ids')  List<String>? parishIds, @JsonKey(name: 'published_at')  DateTime? publishedAt, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _BlogPost():
return $default(_that.id,_that.slug,_that.title,_that.status,_that.content,_that.excerpt,_that.authorId,_that.coverImageUrl,_that.parishIds,_that.publishedAt,_that.createdAt,_that.updatedAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String slug,  String title,  String status,  String? content,  String? excerpt, @JsonKey(name: 'author_id')  String? authorId, @JsonKey(name: 'cover_image_url')  String? coverImageUrl, @JsonKey(name: 'parish_ids')  List<String>? parishIds, @JsonKey(name: 'published_at')  DateTime? publishedAt, @JsonKey(name: 'created_at')  DateTime? createdAt, @JsonKey(name: 'updated_at')  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _BlogPost() when $default != null:
return $default(_that.id,_that.slug,_that.title,_that.status,_that.content,_that.excerpt,_that.authorId,_that.coverImageUrl,_that.parishIds,_that.publishedAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BlogPost extends BlogPost {
  const _BlogPost({required this.id, required this.slug, required this.title, required this.status, this.content, this.excerpt, @JsonKey(name: 'author_id') this.authorId, @JsonKey(name: 'cover_image_url') this.coverImageUrl, @JsonKey(name: 'parish_ids') final  List<String>? parishIds, @JsonKey(name: 'published_at') this.publishedAt, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt}): _parishIds = parishIds,super._();
  factory _BlogPost.fromJson(Map<String, dynamic> json) => _$BlogPostFromJson(json);

@override final  String id;
@override final  String slug;
@override final  String title;
@override final  String status;
@override final  String? content;
@override final  String? excerpt;
@override@JsonKey(name: 'author_id') final  String? authorId;
@override@JsonKey(name: 'cover_image_url') final  String? coverImageUrl;
 final  List<String>? _parishIds;
@override@JsonKey(name: 'parish_ids') List<String>? get parishIds {
  final value = _parishIds;
  if (value == null) return null;
  if (_parishIds is EqualUnmodifiableListView) return _parishIds;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override@JsonKey(name: 'published_at') final  DateTime? publishedAt;
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;
@override@JsonKey(name: 'updated_at') final  DateTime? updatedAt;

/// Create a copy of BlogPost
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BlogPostCopyWith<_BlogPost> get copyWith => __$BlogPostCopyWithImpl<_BlogPost>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BlogPostToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BlogPost&&(identical(other.id, id) || other.id == id)&&(identical(other.slug, slug) || other.slug == slug)&&(identical(other.title, title) || other.title == title)&&(identical(other.status, status) || other.status == status)&&(identical(other.content, content) || other.content == content)&&(identical(other.excerpt, excerpt) || other.excerpt == excerpt)&&(identical(other.authorId, authorId) || other.authorId == authorId)&&(identical(other.coverImageUrl, coverImageUrl) || other.coverImageUrl == coverImageUrl)&&const DeepCollectionEquality().equals(other._parishIds, _parishIds)&&(identical(other.publishedAt, publishedAt) || other.publishedAt == publishedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,slug,title,status,content,excerpt,authorId,coverImageUrl,const DeepCollectionEquality().hash(_parishIds),publishedAt,createdAt,updatedAt);

@override
String toString() {
  return 'BlogPost(id: $id, slug: $slug, title: $title, status: $status, content: $content, excerpt: $excerpt, authorId: $authorId, coverImageUrl: $coverImageUrl, parishIds: $parishIds, publishedAt: $publishedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$BlogPostCopyWith<$Res> implements $BlogPostCopyWith<$Res> {
  factory _$BlogPostCopyWith(_BlogPost value, $Res Function(_BlogPost) _then) = __$BlogPostCopyWithImpl;
@override @useResult
$Res call({
 String id, String slug, String title, String status, String? content, String? excerpt,@JsonKey(name: 'author_id') String? authorId,@JsonKey(name: 'cover_image_url') String? coverImageUrl,@JsonKey(name: 'parish_ids') List<String>? parishIds,@JsonKey(name: 'published_at') DateTime? publishedAt,@JsonKey(name: 'created_at') DateTime? createdAt,@JsonKey(name: 'updated_at') DateTime? updatedAt
});




}
/// @nodoc
class __$BlogPostCopyWithImpl<$Res>
    implements _$BlogPostCopyWith<$Res> {
  __$BlogPostCopyWithImpl(this._self, this._then);

  final _BlogPost _self;
  final $Res Function(_BlogPost) _then;

/// Create a copy of BlogPost
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? slug = null,Object? title = null,Object? status = null,Object? content = freezed,Object? excerpt = freezed,Object? authorId = freezed,Object? coverImageUrl = freezed,Object? parishIds = freezed,Object? publishedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_BlogPost(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,slug: null == slug ? _self.slug : slug // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,content: freezed == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String?,excerpt: freezed == excerpt ? _self.excerpt : excerpt // ignore: cast_nullable_to_non_nullable
as String?,authorId: freezed == authorId ? _self.authorId : authorId // ignore: cast_nullable_to_non_nullable
as String?,coverImageUrl: freezed == coverImageUrl ? _self.coverImageUrl : coverImageUrl // ignore: cast_nullable_to_non_nullable
as String?,parishIds: freezed == parishIds ? _self._parishIds : parishIds // ignore: cast_nullable_to_non_nullable
as List<String>?,publishedAt: freezed == publishedAt ? _self.publishedAt : publishedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
