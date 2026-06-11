class User {
  String? matric;
  String? username;
  String? bio;
  String? profilePic;

  User({this.matric, this.username, this.bio, this.profilePic});

  User.fromJson(Map<String, dynamic> json) {
    matric = json['matric'];
    username = json['username'];
    bio = json['bio'];
    profilePic = json['profile_pic'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['matric'] = matric;
    data['username'] = username;
    data['bio'] = bio;
    data['profile_pic'] = profilePic;
    return data;
  }
}