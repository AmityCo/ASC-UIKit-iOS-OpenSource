//
//  ProductTaggingButtonElement.swift
//  AmityUIKit4
//
//  Created by Manuchet Rungraksa on 16/2/2569 BE.
//

struct ProductTaggingButtonElement: AmityElementView {
    
    var pageId: PageId?
    var componentId: ComponentId?
    
    var id: ElementId {
        .productTaggingButton
    }
    
    @EnvironmentObject private var viewConfig: AmityViewConfigController
    
    let productCount: Int
    let onClick: () -> Void
    
    init(pageId: PageId? = nil, componentId: ComponentId? = nil, productCount: Int = 0, onClick: @escaping () -> Void) {
        self.pageId = pageId
        self.componentId = componentId
        self.productCount = productCount
        self.onClick = onClick
    }
    
    var body: some View {
        Button {
            onClick()
        } label: {
            ZStack(alignment: .topTrailing) {
                // Main button
                Image(AmityIcon.LiveStream.productTaggingIcon.imageResource)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.white)
                    .circularBackground(radius: 40, color: Color(viewConfig.defaultDarkTheme.baseColorShade4))
                
                // Badge overlay
                if productCount > 0 {
                    Text(productCount > 99 ? "99+" : "\(productCount)")
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .frame(minWidth: 22)
                        .background(Color(red: 250/255, green: 77/255, blue: 48/255)) // #FA4D30
                        .clipShape(Capsule())
                        .offset(x: 8, y: -8)
                }
            }
        }
        .accessibilityLabel(productCount > 0 ? "\(productCount) products tagged" : "Add products")
    }
}
