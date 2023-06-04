//
//  PermissionDeniedView.swift
// AVAuditor
//
//  Created by Eli Hartnett on 5/6/23.
//

import SwiftUI

struct PermissionDeniedView: View {

    var body: some View {

        HStack {
            Text(Constants.permissionDenied)
                .foregroundColor(.red)

            Spacer()
        }
    }
}

struct PermissionDeniedView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionDeniedView()
    }
}
