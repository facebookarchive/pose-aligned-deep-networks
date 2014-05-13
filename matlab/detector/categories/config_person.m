function K=config_person

K.DISABLE_PATCH_ROTATIONS=false;
K.NUM_POSELET_CANDIDATES=1200;
K.NUM_POSELETS = 150;

K.PATCH_DIMS = [96 64; 64 64; 64 96; 128 64];

K.L_Shoulder = 1;
K.L_Elbow    = 2;
K.L_Wrist    = 3;
K.R_Shoulder = 4;
K.R_Elbow    = 5;
K.R_Wrist    = 6;
K.L_Hip      = 7;
K.L_Knee     = 8;
K.L_Ankle    = 9;
K.R_Hip      = 10;
K.R_Knee     = 11;
K.R_Ankle    = 12;

K.L_Eye      = 13;
K.R_Eye      = 14;
K.L_Ear      = 15;
K.R_Ear      = 16;
K.Nose       = 17;

K.L_Foot     = 18;
K.R_Foot     = 19;

K.HeadBack   = 20;

K.NumPrimaryKeypoints = 20;

K.M_Shoulder = 21;
K.M_Hip      = 22;
K.M_Ear      = 23;
K.M_Torso    = 24;
K.M_LUpperArm    = 25;
K.M_RUpperArm    = 26;
K.M_LLowerArm    = 27;
K.M_RLowerArm    = 28;
K.M_LUpperLeg    = 29;
K.M_RUpperLeg    = 30;
K.M_LLowerLeg    = 31;
K.M_RLowerLeg    = 32;
K.M_Eye = 33;

K.KEYPOINT_FLIPMAP = [
    K.L_Shoulder K.R_Shoulder
    K.L_Elbow    K.R_Elbow
    K.L_Wrist    K.R_Wrist
    K.R_Shoulder K.L_Shoulder
    K.R_Elbow    K.L_Elbow
    K.R_Wrist    K.L_Wrist
    K.L_Hip      K.R_Hip
    K.L_Knee     K.R_Knee
    K.L_Ankle    K.R_Ankle
    K.R_Hip      K.L_Hip
    K.R_Knee     K.L_Knee
    K.R_Ankle    K.L_Ankle
    K.L_Eye      K.R_Eye
    K.R_Eye      K.L_Eye
    K.L_Ear      K.R_Ear
    K.R_Ear      K.L_Ear
    K.L_Foot     K.R_Foot
    K.R_Foot     K.L_Foot
    K.M_LUpperArm K.M_RUpperArm
    K.M_RUpperArm K.M_LUpperArm
    K.M_LLowerArm K.M_RLowerArm
    K.M_RLowerArm K.M_LLowerArm
    K.M_LUpperLeg K.M_RUpperLeg
    K.M_RUpperLeg K.M_LUpperLeg
    K.M_LLowerLeg K.M_RLowerLeg
    K.M_RLowerLeg K.M_LLowerLeg
    ];

% If these keypoints are missing the distance penalty is low
K.OPTIONAL_KEYPOINTS = [K.L_Ear K.R_Ear];

K.MID_KEYPOINTS = [
   K.M_Shoulder  K.L_Shoulder  K.R_Shoulder
   K.M_Hip       K.L_Hip       K.R_Hip
   K.M_Ear       K.L_Ear       K.R_Ear
   K.M_Torso     K.M_Hip       K.M_Shoulder
   K.M_LUpperArm K.L_Shoulder  K.L_Elbow
   K.M_LLowerArm K.L_Elbow     K.L_Wrist
   K.M_LUpperLeg K.L_Hip       K.L_Knee
   K.M_LLowerLeg K.L_Knee     K.L_Ankle
   K.M_RUpperArm K.R_Shoulder  K.R_Elbow
   K.M_RLowerArm K.R_Elbow     K.R_Wrist
   K.M_RUpperLeg K.R_Hip       K.R_Knee
   K.M_RLowerLeg K.R_Knee     K.R_Ankle
   K.M_Eye       K.R_Eye     K.L_Eye
];


K.Labels = {'L_Shoulder','L_Elbow','L_Wrist','R_Shoulder','R_Elbow','R_Wrist',...
    'L_Hip','L_Knee','L_Ankle','R_Hip','R_Knee','R_Ankle',...
    'L_Eye','R_Eye','L_Ear','R_Ear','Nose','L_Toes','R_Toes','B_Head','M_Shoulder','M_Hip','M_Ear','M_Torso',...
    'M_LUpperArm','M_RUpperArm','M_LLowerArm','M_RLowerArm',...
    'M_LUpperLeg','M_RUpperLeg','M_LLowerLeg','M_RLowerLeg','M_Eye'};
K.NumLabels = length(K.Labels);

K.segs = [K.L_Shoulder K.R_Shoulder 120 120 120; ...
    K.L_Hip      K.R_Hip      67   67   67;  ...
    K.L_Shoulder K.L_Elbow    96   96   96; ...
    K.L_Elbow    K.L_Wrist    80.5 80.5 80.5; ...
    K.R_Shoulder K.R_Elbow    96   96   96; ...
    K.R_Elbow    K.R_Wrist    80.5 80.5 80.5; ...
    K.L_Hip      K.L_Knee     144  144  144; ...
    K.L_Knee     K.L_Ankle    130  130  130; ...
    K.L_Ankle    K.L_Foot     nan  nan  nan; ...
    K.R_Hip      K.R_Knee     144  144  144; ...
    K.R_Knee     K.R_Ankle    130  130  130; ...
    K.R_Ankle    K.R_Foot     nan  nan  nan; ...
    K.M_Shoulder K.M_Hip      153  153  153; ...
    K.L_Eye      K.R_Eye      nan  nan  nan; ...
    K.L_Eye      K.Nose       nan  nan  nan; ...
    K.R_Eye      K.Nose       nan  nan  nan; ...
    K.L_Hip      K.L_Shoulder nan  nan  nan; ...
    K.R_Hip      K.R_Shoulder nan  nan  nan; ...
    K.L_Ear      K.L_Eye      nan  nan  nan; ...
    K.R_Ear      K.R_Eye      nan  nan  nan; ...
    K.L_Ear      K.HeadBack   nan  nan  nan; ...
    K.R_Ear      K.HeadBack   nan  nan  nan; ...
    K.L_Ear      K.Nose       nan  nan  nan; ...
    K.R_Ear      K.Nose       nan  nan  nan; ...
    ];

K.AreaNames = { 'Occluder', 'Face', 'Hair', 'UpperClothes', 'LeftArm', 'RightArm', ...
    'LowerClothes','LeftLeg','RightLeg','LeftShoe','RightShoe','Neck','Bag','Hat',...
    'LeftGlove','RightGlove','LeftSock','RightSock','Sunglasses','Dress','BadSegment' };
K.A_Occluder     = 1;
K.A_Face         = 2;
K.A_Hair         = 3;
K.A_UpperClothes = 4;
K.A_LeftArm      = 5;
K.A_RightArm     = 6;
K.A_LowerClothes = 7;
K.A_LeftLeg      = 8;
K.A_RightLeg     = 9;
K.A_LeftShoe     = 10;
K.A_RightShoe    = 11;
K.A_Neck         = 12;
K.A_Bag          = 13;
K.A_Hat          = 14;
K.A_LeftGlove    = 15;
K.A_RightGlove   = 16;
K.A_LeftSock     = 17;
K.A_RightSock    = 18;
K.A_Sunglasses   = 19;
K.A_Dress        = 20;
K.A_BadSegment   = 21;

% Must be in the same order as above
K.AREA_FLIPMAP = [
    K.A_Occluder     K.A_Occluder
    K.A_Face         K.A_Face
    K.A_Hair         K.A_Hair
    K.A_UpperClothes K.A_UpperClothes
    K.A_LeftArm      K.A_RightArm
    K.A_RightArm     K.A_LeftArm
    K.A_LowerClothes K.A_LowerClothes
    K.A_LeftLeg      K.A_RightLeg
    K.A_RightLeg     K.A_LeftLeg
    K.A_LeftShoe     K.A_RightShoe
    K.A_RightShoe    K.A_LeftShoe
    K.A_Neck         K.A_Neck
    K.A_Bag          K.A_Bag
    K.A_Hat          K.A_Hat
    K.A_LeftGlove    K.A_RightGlove
    K.A_RightGlove   K.A_LeftGlove
    K.A_LeftSock     K.A_RightSock
    K.A_RightSock    K.A_LeftSock
    K.A_Sunglasses   K.A_Sunglasses
    K.A_Dress        K.A_Dress
    K.A_BadSegment   K.A_BadSegment
    ];
assert(isequal(K.AREA_FLIPMAP(:,1),(1:length(K.AreaNames))'));

